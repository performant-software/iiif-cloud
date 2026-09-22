module Exceptions
  class FileNotUploadedError < StandardError; end
  class PDFExtractionError < StandardError; end
  class PDFPageConversionError < StandardError; end
  class EmptyPDFError < StandardError; end
end