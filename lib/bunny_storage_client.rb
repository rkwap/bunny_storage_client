# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'logger'

# BunnyStorageClient is a Ruby SDK for interacting with BunnyCDN storage services.
# API Reference: https://docs.bunny.net/reference/storage-api
class BunnyStorageClient
  VERSION = '1.0.1'
  BASE_URL = 'https://storage.bunnycdn.com/'

  # Initializes the SDK with access credentials and optional logger.
  #
  # @param access_key [String] the access key for storage operations
  # @param api_key [String] the API key for cache purging
  # @param storage_zone_name [String, nil] the default storage zone name
  # @param logger [Logger] the logger instance for logging errors and info
  def initialize(access_key, api_key, storage_zone_name = nil, region = nil, logger = Logger.new($stdout))
    @access_key = access_key
    @api_key = api_key
    @region = region
    @storage_zone_name = storage_zone_name
    @logger = logger

    @base_url = @region ? "https://#{@region}.storage.bunnycdn.com/" : BASE_URL
  end

  # Sets the object filename and optional storage zone name for operations.
  #
  # @param filename [String] the name of the file
  # @param storage_zone_name [String, nil] the storage zone name
  # @return [BunnyStorageClient] the instance of the SDK
  def object(filename, storage_zone_name = nil)
    @filename = filename
    @storage_zone_name = storage_zone_name || @storage_zone_name
    self
  end

  # Retrieves a file from BunnyCDN storage.
  #
  # @param storage_zone_name [String, nil] the storage zone name
  # @param filename [String, nil] the name of the file
  # @return [String, nil] the file content
  def get_file(storage_zone_name: nil, filename: nil, as: :string)
    storage_zone_name ||= @storage_zone_name
    filename ||= @filename

    uri = build_uri(storage_zone_name, filename)
    request = Net::HTTP::Get.new(uri)
    request['AccessKey'] = @access_key
    request['accept'] = '*/*'
    response = make_request(uri, request)

    raise StandardError, "#{response.code} #{response.body}" unless success_code?(response.code)

    if as == :file
      generate_tempfile(filename, response.body)
    else
      response.body
    end
  rescue StandardError => e
    @logger.error("Failed to get file from #{storage_zone_name}/#{filename}: #{e.message}")
    nil
  end

  def exist?(storage_zone_name: nil, filename: nil)
    storage_zone_name ||= @storage_zone_name
    filename ||= @filename

    uri = build_uri(storage_zone_name, filename)

    # First, send a GET request to check if the file exists
    # Maybe HEAD will be available in the future
    head_request = Net::HTTP::Get.new(uri)
    head_request['AccessKey'] = @access_key
    head_request['accept'] = '*/*'

    head_response = make_request(uri, head_request)

    # Check if the file exists (status code 200)
    if head_response.code != '200'
      return false
    end

    true
  end

  # Uploads a file to BunnyCDN storage.
  #
  # @param storage_zone_name [String, nil] the storage zone name
  # @param filename [String, nil] the name of the file
  # @param body [String, File, Tempfile] the file content
  def upload_file(storage_zone_name: nil, filename: nil, body:)
    storage_zone_name ||= @storage_zone_name
    filename ||= @filename
    uri = build_uri(storage_zone_name, filename)
    request = Net::HTTP::Put.new(uri)
    request['AccessKey'] = @access_key
    request['content-type'] = 'application/octet-stream'

    if body.respond_to?(:read)
      body.rewind if body.respond_to?(:rewind) # Reset to the beginning if needed
      request.body = body.read
    else
      request.body = body.to_s # Default to converting the body to a string
    end

    response = make_request(uri, request)

    raise StandardError, "Response code #{response.code} is not OK!" unless success_code?(response.code)
  rescue StandardError => e
    @logger.error("Failed to upload file to #{storage_zone_name}/#{filename}: #{e.message}")
    raise
  end

  # Deletes a file from BunnyCDN storage.
  #
  # @param storage_zone_name [String, nil] the storage zone name
  # @param filename [String, nil] the name of the file
  # @return [Bool, nil] true if the file was deleted successfully
  def delete_file(storage_zone_name: nil, filename: nil)
    storage_zone_name ||= @storage_zone_name
    filename ||= @filename
    uri = build_uri(storage_zone_name, filename)
    request = Net::HTTP::Delete.new(uri)
    request['AccessKey'] = @access_key
    response = make_request(uri, request)

    # hack, 500 is also not found
    raise StandardError, "Response code #{response.code} is not OK!" if !success_code?(response.code) && response.code != "404" && response.code != "500"

    true
  rescue StandardError => e
    @logger.error("Failed to delete file: #{e.message}")
    raise
  end

  # Purges the cache for a specific file in BunnyCDN.
  #
  # @param storage_zone_name [String, nil] the storage zone name
  # @param filename [String, nil] the name of the file
  # @return [String, nil] the response code
  def purge_cache(storage_zone_name: nil, filename: nil)
    storage_zone_name ||= @storage_zone_name
    filename ||= @filename
    url = "https://#{storage_zone_name}.b-cdn.net/#{filename}"
    uri = URI("https://api.bunny.net/purge?url=#{url}&async=true")
    request = Net::HTTP::Post.new(uri)
    request['AccessKey'] = @api_key
    response = make_request(uri, request)

    response.code
  rescue StandardError => e
    @logger.error("Failed to purge cache for #{storage_zone_name}/#{filename}: #{e.message}")
    nil
  end

  private

  def build_uri(storage_zone_name, filename)
    url = File.join(@base_url, storage_zone_name, filename)
    url = url[...-1] if url.end_with?(File::SEPARATOR)
    URI(url)
  end

  def make_request(uri, request)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    https.open_timeout = 3
    https.read_timeout = 5
    https.request(request)
  end

  def generate_tempfile(filename, body)
    file = Tempfile.new(filename)
    file.write(body)
    file.rewind
    file
  end

  def success_code?(code)
    code.to_i.between?(200, 299)
  end
end
