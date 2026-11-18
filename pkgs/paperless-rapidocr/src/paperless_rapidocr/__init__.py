"""Paperless-ngx RapidOCR parser plugin."""

__all__ = ["RapidOcrDocumentParser"]


def __getattr__(name: str):
    if name == "RapidOcrDocumentParser":
        from paperless_rapidocr.parser import RapidOcrDocumentParser

        return RapidOcrDocumentParser
    raise AttributeError(name)
