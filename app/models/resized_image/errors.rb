module ResizedImage::Errors
  class FailedToDownload < StandardError; end
  class FailedToUpload < StandardError; end
  class UnsupportedType < StandardError; end
  class UnsupportedURL < StandardError; end
end
