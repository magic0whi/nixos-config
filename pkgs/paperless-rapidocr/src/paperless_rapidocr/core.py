"""RapidOCR (PaddleOCR PP-OCRv4, ONNX) document OCR.

Pure helpers with no Django/Paperless imports, so they can be exercised
standalone. The parser plugin in :mod:`paperless_rapidocr.parser` is a thin
Paperless integration around :func:`ocr_document`.
"""

from __future__ import annotations

import logging
import os
import re
from dataclasses import dataclass
from pathlib import Path

import pymupdf
from PIL import Image
from PIL import ImageOps

logger = logging.getLogger("paperless.parsing.rapidocr")

WORD_RE = re.compile(r"\w", re.UNICODE)
# Glyphs with no usable ToUnicode mapping extract as U+FFFF (MuPDF) or U+FFFD
# (poppler). A layer made only of these is not text at all.
JUNK_CHAR_RE = re.compile("[\ufffd\ufffe\uffff]")

CJK_FONT = "china-s"  # MuPDF built-in Droid Sans Fallback (covers zh-Hans/zh-Hant)
DEFAULT_DPI = 300

_engine = None
_TRUTHY = {"1", "true", "yes", "on", "auto"}


def _gpu_requested() -> bool:
    """CUDA is used by default when available; set the env var to 0 to force CPU."""
    value = os.environ.get("PAPERLESS_RAPIDOCR_GPU", "auto").strip().lower()
    return value in _TRUTHY


def _cuda_available() -> bool:
    try:
        import onnxruntime as ort

        return "CUDAExecutionProvider" in ort.get_available_providers()
    except Exception:
        return False


def _patch_rapidocr_cuda() -> None:
    """RapidOCR 1.4.4 requires ``onnxruntime.get_device() == "GPU"``.

    The Nix build enables OpenVINO alongside CUDA, so ``get_device()`` returns
    ``"GPU-OPENVINO_CPU"`` and RapidOCR silently falls back to the CPU
    provider even though ``CUDAExecutionProvider`` is available. Trust the
    provider list instead.
    """
    from rapidocr_onnxruntime.utils import infer_engine as ie

    if getattr(ie.OrtInferSession, "_paperless_cuda_patch", False):
        return

    def _check_cuda(self) -> bool:
        if not self.cfg_use_cuda:
            return False
        if ie.EP.CUDA_EP.value in self.had_providers:
            return True
        logger.warning(
            "RapidOCR: CUDAExecutionProvider missing (%s); using %s",
            self.had_providers,
            self.had_providers[0] if self.had_providers else "CPU",
        )
        return False

    ie.OrtInferSession._check_cuda = _check_cuda
    ie.OrtInferSession._paperless_cuda_patch = True


def get_engine():
    """Return a process-wide RapidOCR engine (model load is expensive)."""
    global _engine
    if _engine is None:
        from rapidocr_onnxruntime import RapidOCR

        # Paperless exports OMP_NUM_THREADS=1 for the Tesseract pipeline; set
        # the ONNX Runtime pool explicitly so OCR is not single-threaded.
        try:
            threads = int(os.environ.get("PAPERLESS_RAPIDOCR_THREADS", "0"))
        except ValueError:
            threads = 0
        if threads <= 0:
            threads = min(4, os.cpu_count() or 1)

        kwargs = {"intra_op_num_threads": threads}
        if _gpu_requested():
            if _cuda_available():
                _patch_rapidocr_cuda()
                kwargs.update(
                    det_use_cuda=True,
                    cls_use_cuda=True,
                    rec_use_cuda=True,
                )
                logger.info("RapidOCR: using CUDAExecutionProvider")
            else:
                logger.info(
                    "RapidOCR: GPU requested but CUDAExecutionProvider is unavailable, using CPU",
                )
        _engine = RapidOCR(**kwargs)
    return _engine


@dataclass
class OcrResult:
    text: str
    letters: int
    pages: int


@dataclass
class PdfProfile:
    """Cheap summary of a PDF's existing text layer.

    *text_chars* only counts extractable characters: replacement and unmapped
    glyphs are ignored, so a broken text layer (Type 3 fonts, missing
    ToUnicode) does not count as text.

    *invisible_text* is true when the layer was added by OCR (glyphs painted
    with text render mode 3), as opposed to a born-digital PDF where the text
    is the visible content itself.
    """

    pages: int
    text_chars: int
    invisible_text: bool

    @property
    def has_text(self) -> bool:
        return self.text_chars >= 64


def _extractable_chars(page: "pymupdf.Page") -> int:
    """Length of *page*'s text layer without whitespace or unmapped glyphs."""
    return len(JUNK_CHAR_RE.sub("", re.sub(r"\s+", "", page.get_text())))


def _is_invisible_text(page: "pymupdf.Page") -> bool:
    """True when every glyph on *page* is drawn in render mode 3 (OCR layer)."""
    try:
        spans = page.get_texttrace()
    except Exception:
        return False
    return bool(spans) and all(span.get("type") == 3 for span in spans)


def pdf_profile(path: Path, *, pages: int = 3) -> PdfProfile:
    """Summarise the text layer of the first *pages* pages."""
    try:
        with pymupdf.open(path) as doc:
            if not doc.is_pdf:
                return PdfProfile(pages=0, text_chars=0, invisible_text=False)
            limit = min(pages, doc.page_count)
            chars = 0
            with_text = 0
            invisible = 0
            for index in range(limit):
                page = doc[index]
                page_chars = _extractable_chars(page)
                chars += page_chars
                if page_chars:
                    with_text += 1
                    invisible += _is_invisible_text(page)
    except Exception:
        return PdfProfile(pages=0, text_chars=0, invisible_text=False)
    return PdfProfile(
        pages=limit,
        text_chars=chars,
        invisible_text=with_text > 0 and invisible == with_text,
    )


def pdf_native_text(path: Path) -> str:
    """Extract a PDF's own text layer, dropping unmapped glyphs."""
    parts: list[str] = []
    with pymupdf.open(path) as doc:
        for page in doc:
            parts.append(JUNK_CHAR_RE.sub("", page.get_text()))
    return "\n".join(part for part in parts if part.strip())


def _reading_order(lines: list) -> list:
    """Sort RapidOCR boxes top-to-bottom, left-to-right."""
    if not lines:
        return []
    heights = [abs(box[3][1] - box[0][1]) for box, _text, _conf in lines if box]
    tol = max(8.0, (sum(heights) / len(heights)) * 0.6) if heights else 12.0
    return sorted(
        lines,
        key=lambda item: (
            round(min(pt[1] for pt in item[0]) / tol),
            min(pt[0] for pt in item[0]),
        ),
    )


def _insert_text_layer(page: "pymupdf.Page", lines: list, pix: "pymupdf.Pixmap") -> None:
    sx = page.rect.width / pix.width
    sy = page.rect.height / pix.height
    for box, text, _conf in lines:
        if not text.strip():
            continue
        xs = [pt[0] for pt in box]
        ys = [pt[1] for pt in box]
        x0, x1 = min(xs), max(xs)
        y0, y1 = min(ys), max(ys)
        size = max(4.0, min(48.0, (y1 - y0) * sy * 0.8))
        page.insert_text(
            (x0 * sx, y1 * sy),
            text,
            fontname=CJK_FONT,
            fontsize=size,
            render_mode=3,  # invisible, text layer only
        )


def _load_as_pdf(src: Path, tmpdir: Path, dpi: int) -> tuple["pymupdf.Document", int]:
    """Open *src* as a PDF document. Images are normalised (EXIF) first."""
    doc = pymupdf.open(src)
    if doc.is_pdf:
        return doc, dpi

    doc.close()
    with Image.open(src) as im:
        im = ImageOps.exif_transpose(im).convert("RGB")
        img_dpi = im.info.get("dpi", (dpi, dpi))[0]
        img_dpi = int(img_dpi) if isinstance(img_dpi, (int, float)) and img_dpi > 0 else dpi
        png = tmpdir / "image-page.png"
        im.save(png, dpi=(img_dpi, img_dpi))
    with pymupdf.open(png) as img_doc:
        pdf_bytes = img_doc.convert_to_pdf()
    return pymupdf.open("pdf", pdf_bytes), img_dpi


def ocr_document(
    src: Path,
    dst: Path | None,
    *,
    dpi: int = DEFAULT_DPI,
    max_pages: int | None = None,
    strip_text: bool = False,
    tmpdir: Path,
) -> OcrResult:
    """OCR *src* (PDF or image) and optionally write a searchable PDF to *dst*.

    Text is added as an invisible layer, so page images are left untouched.
    With *strip_text* the existing text layer is removed first (a scan that
    already carries OCR); images and vector art are preserved.
    """
    engine = get_engine()
    doc, page_dpi = _load_as_pdf(src, tmpdir, dpi)
    all_text: list[str] = []
    try:
        limit = doc.page_count if max_pages is None else min(max_pages, doc.page_count)

        if strip_text and doc.is_pdf:
            for index in range(limit):
                page = doc[index]
                page.add_redact_annot(page.rect)
                page.apply_redactions(
                    images=pymupdf.PDF_REDACT_IMAGE_NONE,
                    graphics=pymupdf.PDF_REDACT_LINE_ART_NONE,
                    text=pymupdf.PDF_REDACT_TEXT_REMOVE,
                )

        for index in range(limit):
            page = doc[index]
            pix = page.get_pixmap(dpi=page_dpi, colorspace=pymupdf.csRGB, alpha=False)
            png = tmpdir / f"page-{index}.png"
            pix.save(png)
            result, _elapse = engine(str(png))
            lines = _reading_order(result or [])
            all_text.extend(text for _box, text, _conf in lines)
            _insert_text_layer(page, lines, pix)
            png.unlink(missing_ok=True)

        text = "\n".join(t for t in all_text if t.strip())
        if dst is not None:
            doc.save(dst, garbage=3, deflate=True)
    finally:
        doc.close()

    letters = len(WORD_RE.findall(text))
    return OcrResult(
        text=text,
        letters=letters,
        pages=limit,
    )
