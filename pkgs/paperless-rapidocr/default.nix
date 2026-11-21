# TODO: human review
# RapidOCR parser plugin. Runtime knobs are environment variables; set them
# with `services.paperless.settings`
#   PAPERLESS_RAPIDOCR_DISABLED = 1      # disable RapidOCR, Tesseract only
#   PAPERLESS_RAPIDOCR_GPU = 0           # force CPU (CUDA is used when available)
#   PAPERLESS_RAPIDOCR_DPI = 300         # OCR/text-layer render DPI
#   PAPERLESS_RAPIDOCR_THREADS = 4       # ONNX intra-op threads (default min(4, cpus))
{
  lib,
  pythonPackages,
}:
pythonPackages.buildPythonPackage {
  pname = "paperless-rapidocr";
  version = "0.4.0";
  format = "pyproject";

  src = ./.;

  nativeBuildInputs = [ pythonPackages.setuptools ];

  propagatedBuildInputs = with pythonPackages; [
    pillow
    pymupdf
    rapidocr-onnxruntime
  ];

  # Imports need a configured Django/Paperless environment.
  doCheck = false;

  meta = {
    description = "Paperless-ngx parser plugin using RapidOCR (PaddleOCR PP-OCRv4, ONNX)";
    homepage = "https://github.com/RapidAI/RapidOCR";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
