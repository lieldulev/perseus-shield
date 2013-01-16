class ResizedImage

  attr_accessor :url, :width, :height, :uniq_id, :cache_id, :local_image, :remote_url, :image_extension

  def initialize(url, width = nil, height = nil, use_cache = true)
    raise Errors::UnsupportedURL unless ResizedImage.url_valid?(url)
    @url = url
    @width = width
    @height = height
    load_from_cache if use_cache && exist?
  end

  def self.gen_uniq_id(url, width = nil, height = nil)
    # strip (s)ftp or http(s) schemes, concat width and height and md5 it.
    Digest::MD5.hexdigest("#{url.gsub(/(https?|s?ftp):\/\//, '')}_#{width.to_s}_#{height.to_s}i")
  end

  def self.gen_cache_id(uniq_id)
    "#{PerseusShield.config.cache_key_prefix}:#{uniq_id}"
  end

  def self.url_valid?(url)
    return false unless url =~ /#{PerseusShield.config.url_regex}/
    begin
      URI.parse(url)
    rescue Exception => e
      return false
    end
    return true
  end
  def exist?
    Rails.cache.exist?(cache_id)
  end

  def resize # resize if doesn't exist or return existing
    return remote_url if exist?
    resize!
  end

  def resize! #forced resize + upload
    if width.blank? && height.blank? # just download
      download_with_redirects url
    else # resize
      resize_image url, width, height
    end
    return false unless @local_image
    return false unless upload_image
    remote_url # make sure to generate
    save_to_cache
    remote_url
  end

  def uniq_id
    @uniq_id ||= ResizedImage.gen_uniq_id(url, width, height)
  end
  def cache_id
    @cache_id ||= ResizedImage.gen_cache_id(uniq_id)
  end
  def remote_url
    @remote_url ||= "#{PerseusShield.config.external_uri}/#{self.remote_path}"
  end

  def remote_path
    "#{uniq_id.to(3).chars.to_a.join('/')}/#{uniq_id}.#{self.image_extension}"
  end

  def image_extension
    @image_extension ||= File.extname(URI.parse(url).path).from(1)
  end

  private

    def upload_image
      begin
        conn = Fog::Storage.new({:provider=>'AWS', :aws_access_key_id => PerseusShield.config.aws_key, :aws_secret_access_key => PerseusShield.config.aws_secret})
        directory = conn.directories.get(PerseusShield.config.s3_bucket) || conn.directories.create(:key => PerseusShield.config.s3_bucket, :public=> true)
        file = directory.files.create({:key => "#{PerseusShield.config.s3_root.blank? ? '' : PerseusShield.config.s3_root+'/'}#{remote_path}", :body => File.open(@local_image), :public => true})
        return true if file
      rescue Exception => e
          Rails.logger.info "Failed to upload #{local_image} to #{PerseusShield.config.s3_bucket} : #{PerseusShield.config.s3_root}/#{remote_path} because: #{e.message}"
      end
      return false
    end

    def load_from_cache
      populate_variables Rails.cache.read(cache_id)
    end

    def save_to_cache
      Rails.cache.write(cache_id, cacheable_attributes)
    end

    def delete_from_cache
      Rails.cache.delete(cache_id)
    end

    def cacheable_attributes
      #self.instance_variables.each_with_object({}) { |o,h| h[o.to_s.parameterize]= send(o.to_s.parameterize) }
      self.instance_values.except(*%w(cache_id uniq_id local_image local_resized_image url width height))
    end

    def populate_variables(attributes = {})
      attributes.each {|k, v| send("#{k}=", v)}
    end

    def resize_image(original, width, height)
      result = FastImage.resize(original, width, height)
      if result
        self.image_extension = File.extname(result.path).from(1)
        self.local_image = result.path
        return true
      end
      return false
    end
    def download_with_redirects(url, max_redirects=3)
      timeout = 3
      begin
        con = Faraday.new
        resp = con.get do |req|
          req.url url
          req.options[:timeout] = timeout # open/read timeout in seconds
          req.options[:open_timeout] = timeout # connection open timeout in seconds
        end
        if resp.status < 300 # 20x
          self.image_extension = resp.headers['content-type'].split('/').last.gsub('e','')
          return false unless %w(gif png jpg).include? image_extension
          local = Tempfile.new(['parseus_download', '.png'])
          local.binmode
          local.write resp.body
          local.close
          self.local_image = local.path
        elsif resp.status > 399  # host returned an error
          Rails.logger.info "Failed to download for #{url} since #{resp.status}"
          false
        elsif max_redirects == 0
          Rails.logger.info "Failed to download for #{url} since #{resp.status}"
          false
        elsif [301, 302].include? resp.status # redirect
          Rails.logger.debug "Trying to download #{url} from #{resp.headers['location']} since #{resp.status}"
          return download_with_redirects(resp.headers['location'], (max_redirects-1))
        else
          Rails.logger.info "Failed to download for #{url} since #{resp.status}"
          false
        end
      rescue Exception => e
        Rails.logger.info "Failed to download for #{url} since #{e.message}"
        false
      end
    end

end
