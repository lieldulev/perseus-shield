class ApplicationController < ActionController::Base
  protect_from_forgery

  # http://localhost:3000/r/?url=http%3A%2F%2Fs3.boxee.tv%2Flivetv%2Fprograms%2Fv1%2F8217151_720_540.jpg&width=640&force=true
  def resize
    redirect_to "http#{request.ssl? ? 's' : ''}://#{ResizedImage.new(params[:url], params[:width], params[:height], (!(params[:force] == 'true'))).resize}"
  end

end
