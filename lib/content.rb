require 'content/raw'
require 'content/code'
require 'content/markdown'
require 'rack/utils'

class Content

  include Raw
  include Code
  include Markdown

  def initialize(content_url)
    @content_url = content_url
  end

  def raw
    # Files uploaded to S3 don't have a character encoding. Have to incorrectly
    # assume that everything will use UTF-8 until a proper solution for sending
    # the encoding along with the file is discovered and implemented.
    @raw ||= begin
               Metriks.timer('viso.download-content').time {
                 EM::HttpRequest.new(@content_url).get(:redirects => 3).response.
                   force_encoding(Encoding::UTF_8)
               }
             end
  end

  def escaped_raw
    Rack::Utils.escape_html raw
  end

end
