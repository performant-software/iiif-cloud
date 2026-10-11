module Exceptions
  class FileNotUploadedError < StandardError; end
  class PDFExtractionError < StandardError; end
  class PDFPageConversionError < StandardError; end
  class EmptyPDFError < StandardError; end
  class VideoProbeError < StandardError; end
  class VideoTranscodingError < StandardError; end
end