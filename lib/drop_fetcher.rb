require 'em-synchrony'
require 'em-synchrony/em-http'
require 'yajl'
require 'drop'

class DropFetcher
  class NotFound < StandardError; end

  @base_uri = ENV.fetch 'CLOUDAPP_DOMAIN', 'api.cld.me'
  def self.base_uri() @base_uri end

  @default_domains = ENV.fetch('DEFAULT_DOMAINS', 'cl.ly www.cl.ly').split(' ')
  def self.default_domains() @default_domains end

  def self.fetch(slug)
    Drop.new Yajl::Parser.parse fetch_drop_content(slug),
                                :symbolize_keys => true
  end

private

  def self.fetch_drop_content(slug)
    request = EM::HttpRequest.new("http://#{ base_uri }/#{ slug }").
                              get(:head => { 'Accept'=> 'application/json' })

    raise NotFound unless request.response_header.status == 200

    request.response
  end

end
