"""Paperless-ngx parser plugin backed by RapidOCR (PaddleOCR PP-OCRv4).

Registered through the ``paperless_ngx.parsers`` entry point. It handles every
document the built-in rasterised parser would (images and PDFs), so Tesseract
is no longer used for parsing:

* images and PDFs without a text layer — OCR with RapidOCR
* PDFs whose text layer was added by an OCR engine (invisible glyphs, e.g. an
  old Tesseract pass) — the layer is replaced with RapidOCR output
* born-digital PDFs (visible text) — their own text layer is used as-is; OCR
  would only replace exact text with a transcription and stripping the layer
  would delete the visible page content (the glyphs are the ink)

``OCR_MODE=off`` still defers to the built-in parser, and RapidOCR failures or
empty output fall back to Tesseract as a safety net.
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
from paperless_rapidocr.core import pdf_native_text
from paperless_rapidocr.core import pdf_profile

if TYPE_CHECKING:
    from paperless.parsers import ParserContext

logger = logging.getLogger("paperless.parsing.rapidocr")

SCORE = 15  # beats the built-in parsers (10), below remote OCR (20)
DISABLED_VALUES = {"1", "true", "yes", "on"}


def _flag(name: str) -> bool:
    return os.environ.get(name, "").strip().lower() in DISABLED_VALUES


def _disabled() -> bool:
    return _flag("PAPERLESS_RAPIDOCR_DISABLED")


def _ocr_dpi() -> int:
    try:
        return max(72, int(os.environ.get("PAPERLESS_RAPIDOCR_DPI", "300")))
    except ValueError:
        return 300


class RapidOcrDocumentParser(RasterisedDocumentParser):
    """RapidOCR implementation of the Paperless parser protocol."""

    name = "RapidOCR (PaddleOCR PP-OCRv4, ONNX)"
    version = "0.4.0"
    author = "nixos-configs"
    url = "https://github.com/RapidAI/RapidOCR"

    @classmethod
    def score(
        cls,
        mime_type: str,
        filename: str,  # noqa: ARG003
        path: Path | None = None,  # noqa: ARG003
    ) -> int | None:
        if _disabled() or mime_type not in cls.supported_mime_types():
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

        # Born-digital PDF: the text layer is the visible content, so keep it.
        # There is nothing for OCR to improve (and redacting the layer would
        # erase the page), which also avoids a pointless GPU pass.
        if profile and profile.has_text and not profile.invisible_text:
            try:
                native = pdf_native_text(Path(document_path))
            except Exception as exc:  # noqa: BLE001
                logger.warning(
                    "RapidOCR: native text extraction failed (%s: %s)",
                    type(exc).__name__,
                    exc,
                )
                native = ""
            if native.strip():
                logger.info(
                    "RapidOCR: using the existing text layer (%d chars over %d page(s))",
                    profile.text_chars,
                    profile.pages,
                )
                self.text = re.sub(r"\n{3,}", "\n\n", native)
                return

        # An invisible layer is a previous OCR pass: replace it.
        strip_text = bool(profile and profile.has_text)
        # A document that had a text layer needs a new archive too, otherwise
        # the stale layer survives in the viewer/download copy.
        write_archive = produce_archive or strip_text
        if strip_text:
            logger.info(
                "RapidOCR: replacing existing OCR text layer (%d chars over %d page(s))",
                profile.text_chars,
                profile.pages,
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

        logger.info(
            "RapidOCR: %d page(s), %d chars",
            result.pages,
            len(result.text),
        )
        self.text = re.sub(r"\n{3,}", "\n\n", result.text)
        if write_archive:
            self.archive_path = archive_path
