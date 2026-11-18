"""Paperless-ngx parser plugin backed by RapidOCR (PaddleOCR PP-OCRv4).

Registered through the ``paperless_ngx.parsers`` entry point. It only takes
documents that actually need OCR:

* images (photos/scans) — always
* PDFs without a text layer — always
* scans whose pages are one big image and whose text layer is sparse (a
  previously OCR'd scan) — taken over and the old layer replaced
* born-digital PDFs (text, no page-filling image) — never, the built-in
  Tesseract parser keeps handling those exactly as before

Documents where RapidOCR finds no CJK are kept by default; set
``PAPERLESS_RAPIDOCR_CJK_FALLBACK=1`` to hand Latin-only scans back to
Tesseract (PaddleOCR's recogniser merges Latin words).
"""

from __future__ import annotations

import logging
import os
import re
from pathlib import Path
from typing import TYPE_CHECKING

from paperless.models import ModeChoices
from paperless.parsers.tesseract import RasterisedDocumentParser

from paperless_rapidocr.core import ocr_document
from paperless_rapidocr.core import pdf_profile

if TYPE_CHECKING:
    from paperless.parsers import ParserContext

logger = logging.getLogger("paperless.parsing.rapidocr")

SCORE = 15  # beats the built-in parsers (10), below remote OCR (20)
MIN_CJK_CHARS = 5
MIN_CJK_RATIO = 0.03
DISABLED_VALUES = {"1", "true", "yes", "on"}


def _flag(name: str) -> bool:
    return os.environ.get(name, "").strip().lower() in DISABLED_VALUES


def _disabled() -> bool:
    return _flag("PAPERLESS_RAPIDOCR_DISABLED")


def _skip_existing_text() -> bool:
    """Opt out of re-OCR-ing scans that already carry a text layer."""
    return _flag("PAPERLESS_RAPIDOCR_SKIP_TEXT")


def _cjk_fallback() -> bool:
    """Hand non-CJK scans back to Tesseract (off by default).

    PaddleOCR's recogniser merges Latin words, so Tesseract is better for
    dense English pages; but documents that need OCR in this collection are
    CJK, and a second OCR pass is expensive.
    """
    return _flag("PAPERLESS_RAPIDOCR_CJK_FALLBACK")


def _ocr_dpi() -> int:
    try:
        return max(72, int(os.environ.get("PAPERLESS_RAPIDOCR_DPI", "300")))
    except ValueError:
        return 300


class RapidOcrDocumentParser(RasterisedDocumentParser):
    """RapidOCR implementation of the Paperless parser protocol."""

    name = "RapidOCR (PaddleOCR PP-OCRv4, ONNX)"
    version = "0.3.2"
    author = "nixos-configs"
    url = "https://github.com/RapidAI/RapidOCR"

    @classmethod
    def score(
        cls,
        mime_type: str,
        filename: str,
        path: Path | None = None,
    ) -> int | None:
        if _disabled() or mime_type not in cls.supported_mime_types():
            return None
        # Born-digital PDFs keep their existing text and are left to the
        # built-in parser, which extracts it without OCR-ing. Scans that
        # already carry an (often poor) text layer are still taken over.
        if mime_type == "application/pdf" and path is not None:
            profile = pdf_profile(Path(path))
            if profile.has_text and (
                _skip_existing_text() or not profile.looks_like_scan
            ):
                return None
        return SCORE

    def configure(self, context: ParserContext) -> None:  # noqa: ARG002
        return None

    def parse(
        self,
        document_path: Path,
        mime_type: str,
        *,
        produce_archive: bool = True,
    ) -> None:
        if self.settings.mode == ModeChoices.OFF:
            logger.debug("RapidOCR: OCR_MODE=off, deferring to Tesseract pipeline")
            super().parse(document_path, mime_type, produce_archive=produce_archive)
            return

        archive_path = Path(self.tempdir) / "archive.pdf"
        profile = pdf_profile(Path(document_path)) if mime_type == "application/pdf" else None
        strip_text = bool(profile and profile.has_text)
        # A scan with an old text layer needs a new archive too, otherwise the
        # stale layer survives in the viewer/download copy.
        write_archive = produce_archive or strip_text
        if strip_text:
            logger.info(
                "RapidOCR: replacing existing text layer (%d chars over %d page(s), image cover %.2f)",
                profile.text_chars,
                profile.pages,
                profile.image_cover,
            )
        try:
            result = ocr_document(
                Path(document_path),
                archive_path if write_archive else None,
                dpi=_ocr_dpi(),
                max_pages=self.settings.pages,
                strip_text=strip_text,
                tmpdir=Path(self.tempdir),
            )
        except Exception as exc:  # noqa: BLE001 - any failure must not lose the document
            logger.warning(
                "RapidOCR failed (%s: %s); falling back to Tesseract",
                type(exc).__name__,
                exc,
                exc_info=True,
            )
            super().parse(document_path, mime_type, produce_archive=produce_archive)
            return

        if not result.text.strip():
            logger.warning("RapidOCR produced no text; falling back to Tesseract")
            super().parse(document_path, mime_type, produce_archive=produce_archive)
            return

        if _cjk_fallback() and (
            result.cjk_chars < MIN_CJK_CHARS or result.cjk_ratio < MIN_CJK_RATIO
        ):
            logger.info(
                "RapidOCR found no CJK text (cjk=%d, ratio=%.3f); falling back to Tesseract",
                result.cjk_chars,
                result.cjk_ratio,
            )
            super().parse(document_path, mime_type, produce_archive=produce_archive)
            return

        logger.info(
            "RapidOCR: %d page(s), %d chars, %d CJK (ratio %.2f)",
            result.pages,
            len(result.text),
            result.cjk_chars,
            result.cjk_ratio,
        )
        self.text = re.sub(r"\n{3,}", "\n\n", result.text)
        if write_archive:
            self.archive_path = archive_path
