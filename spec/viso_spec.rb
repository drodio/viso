# encoding: utf-8
require 'helper'
require 'rack/test'
require 'support/vcr'

require 'viso'

describe Viso do
  include Rack::Test::Methods

  def app
    Viso.tap { |app| app.set :environment, :test }
  end

  def get(uri, params = {}, env = {}, &block)
    env.merge!('HTTP_HOST' => 'cl.ly') unless env.has_key?('HTTP_HOST')
    super
  end

  def assert_cached_for(duration)
    assert { headers['Vary']          == 'Accept' }
    assert { headers['Cache-Control'] == "public, max-age=#{ duration }" }
  end

  def assert_not_cached
    deny { headers.has_key? 'Cache-Control' }
  end

  def headers
    last_response.headers
  end


  it "redirects the home page to the domain's home page" do
    EM.synchrony do
      VCR.use_cassette 'domain/success', :erb => { :domain => 'example.org' } do
        get '/', {}, { 'HTTP_HOST' => 'example.org' }
        EM.stop

        assert { last_response.redirect? }
        assert { headers['Location'] == 'http://hhgproject.org' }
        assert_cached_for 3600
      end
    end
  end

  it 'returns a not found response for a nonexistent typed drop' do
    EM.synchrony do
      VCR.use_cassette 'nonexistent' do
        get '/text/hhgttg'
        EM.stop

        assert { last_response.not_found? }
        assert { last_response.body.include?('Sorry, no drops live here') }
        assert_not_cached
      end
    end
  end

  it 'returns a not found response for a nonexistent untyped drop' do
    EM.synchrony do
      VCR.use_cassette 'nonexistent' do
        get '/hhgttg'
        EM.stop

        assert { last_response.not_found? }
        assert { last_response.body.include?('Sorry, no drops live here') }
        assert_not_cached
      end
    end
  end

  it 'redirects a typed content URL to the API' do
    EM.synchrony do
      get '/text/hhgttg/chapter1.txt'
      EM.stop

      assert { last_response.redirect? }
      assert { headers['Location'] == 'http://api.cld.me/text/hhgttg/chapter1.txt' }
      assert_cached_for 900
    end
  end

  it 'redirects an untyped content URL to the API' do
    EM.synchrony do
      get '/hhgttg/chapter1.txt'
      EM.stop

      assert { last_response.redirect? }
      assert { headers['Location'] == 'http://api.cld.me/hhgttg/chapter1.txt' }
      assert_cached_for 900
    end
  end

  it 'redirects file names with an encoded, unfriendly characters to the API' do
    EM.synchrony do
      get '/hhgttg/chapter1%2F%3F%23.txt'
      EM.stop

      assert { last_response.redirect? }
      assert { headers['Location'] == 'http://api.cld.me/hhgttg/chapter1%2F%3F%23.txt' }
      assert_cached_for 900
    end
  end

  it 'redirects a bookmark to the API' do
    EM.synchrony do
      VCR.use_cassette 'bookmark' do
        get '/hhgttg'
        EM.stop

        assert { last_response.redirect? }
        assert { headers['Location'] == 'http://api.cld.me/hhgttg' }
        assert_cached_for 900
      end
    end
  end

  it "redirects a bookmark's content URL to the API" do
    EM.synchrony do
      VCR.use_cassette 'bookmark' do
        get '/hhgttg/content'
        EM.stop

        assert { last_response.redirect? }
        assert { headers['Location'] == 'http://api.cld.me/hhgttg/content' }
        assert_cached_for 900
      end
    end
  end

  it 'displays a typed image drop' do
    EM.synchrony do
      VCR.use_cassette 'image' do
        get '/image/hhgttg'
        EM.stop

        assert { last_response.ok? }

        image_tag = %{<img alt="cover.png" src="http://cl.ly/hhgttg/cover.png">}
        assert { last_response.body.include?(image_tag) }

        assert_cached_for 900
      end
    end
  end

  it 'displays an untyped image drop' do
    EM.synchrony do
      VCR.use_cassette 'image' do
        get '/hhgttg'
        EM.stop

        assert { last_response.ok? }

        image_tag = %{<img alt="cover.png" src="http://cl.ly/hhgttg/cover.png">}
        assert { last_response.body.include?(image_tag) }

        assert_cached_for 900
      end
    end
  end

  it 'displays an image using its custom domain' do
    EM.synchrony do
      VCR.use_cassette 'image_on_custom_domain' do
        get '/hhgttg', {}, { 'HTTP_HOST' => 'dent.com' }
        EM.stop

        assert { last_response.ok? }

        image_tag = %{<img alt="cover.png" src="http://dent.com/hhgttg/cover.png">}
        assert { last_response.body.include?(image_tag) }

        assert_cached_for 900
      end
    end
  end

  it 'displays an image with a custom domain using cl.ly' do
    EM.synchrony do
      VCR.use_cassette 'image_on_custom_domain' do
        get '/hhgttg', {}, { 'HTTP_HOST' => 'cl.ly' }
        EM.stop

        assert { last_response.ok? }

        image_tag = %{<img alt="cover.png" src="http://dent.com/hhgttg/cover.png">}
        assert { last_response.body.include?(image_tag) }

        assert_cached_for 900
      end
    end
  end

  it "returns a not found response for drops without a domain accessed on another user's domain" do
    EM.synchrony do
      VCR.use_cassette 'image' do
        get '/hhgttg', {}, { 'HTTP_HOST' => 'custom.com' }
        EM.stop

        assert { last_response.not_found? }
        assert { last_response.body.include?('Sorry, no drops live here') }
        assert_not_cached
      end
    end
  end

  it "returns a not found response for drops on a custom domain accessed on another user's domain" do
    EM.synchrony do
      VCR.use_cassette 'image_on_custom_domain' do
        get '/hhgttg', {}, { 'HTTP_HOST' => 'custom.com' }
        EM.stop

        assert { last_response.not_found? }
        assert { last_response.body.include?('Sorry, no drops live here') }
        assert_not_cached
      end
    end
  end

  it 'displays an image with a unicode custom domain' do
    EM.synchrony do
      VCR.use_cassette 'image_on_unicode_custom_domain' do
        get '/hhgttg', {}, { 'HTTP_HOST' => 'xn--n3h.com' }
        EM.stop

        assert { last_response.ok? }

        image_tag = %{<img alt="cover.png" src="http://☃.com/hhgttg/cover.png">}
        assert { last_response.body.include?(image_tag) }

        assert_cached_for 900
      end
    end
  end

  it 'displays an original image drop' do
    EM.synchrony do
      VCR.use_cassette 'image' do
        get '/hhgttg/o'
        EM.stop

        assert { last_response.ok? }

        image_tag = %{<img alt="cover.png" src="http://cl.ly/hhgttg/cover.png">}
        assert { last_response.body.include?(image_tag) }

        assert_cached_for 900
      end
    end
  end

  it 'shows a waiting message for pending drops' do
    EM.synchrony do
      VCR.use_cassette 'pending' do
        get '/hhgttg'
        EM.stop

        assert { last_response.ok? }
        image_tag = %{<div class="button disabled waiting">}
        assert { last_response.body.include?(image_tag) }
        assert_not_cached
      end
    end
  end

  it "returns OK for a drop's status" do
    EM.synchrony do
      VCR.use_cassette 'image' do
        get '/hhgttg/status'
        EM.stop

        assert { last_response.ok? }
        assert_not_cached
      end
    end
  end

  it "returns No Content for a pending drop's status" do
    EM.synchrony do
      VCR.use_cassette 'pending' do
        get '/hhgttg/status'
        EM.stop

        assert { last_response.status == 204 }
        assert_not_cached
      end
    end
  end

  it "returns Gone for a nonexistent drop's status" do
    EM.synchrony do
      VCR.use_cassette 'nonexistent' do
        get '/hhgttg/status'
        EM.stop

        assert { last_response.status == 404 }
        assert_not_cached
      end
    end
  end

  it 'shows a download button for an unknown file' do
    EM.synchrony do
      VCR.use_cassette 'unknown' do
        get '/hhgttg'
        EM.stop

        assert { last_response.ok? }

        assert { last_response.body.include?('<body id="other">') }
        deny   { last_response.body.include?("<img") }

        title = %{<title>Chapter 1</title>}
        assert { last_response.body.include?(title) }

        heading = %{<h2>Chapter 1</h2>}
        assert { last_response.body.include?(heading) }

        download_link = %{<a href="http://api.cld.me/hhgttg/download/Chapter_1.blah">Download</a>}
        assert { last_response.body.include?(download_link) }

        view_link = %{<a href="http://cl.ly/hhgttg/Chapter_1.blah">view</a>}
        assert { last_response.body.include?(view_link) }

        assert_cached_for 900
      end
    end
  end

  it 'dumps the content of a typed text drop' do
    EM.synchrony do
      VCR.use_cassette 'text' do
        get '/text/hhgttg'
        EM.stop

        assert { last_response.ok? }

        assert { last_response.body.include?('<body id="text">') }
        deny   { last_response.body.include?("<img") }

        title = %{<title>chapter1.txt</title>}
        assert { last_response.body.include?(title) }

        heading = %{<h2>chapter1.txt</h2>}
        assert { last_response.body.include?(heading) }

        link = %{<a class="embed" href="http://cl.ly/hhgttg/chapter1.txt">Direct link</a>}
        assert { last_response.body.include?(link) }

        content = 'The house stood on a slight rise just on the edge of the village.'
        assert { last_response.body.include? content }

        assert_not_cached
      end
    end
  end

  it 'dumps the content of an untyped text drop' do
    EM.synchrony do
      VCR.use_cassette 'text' do
        get '/hhgttg'
        EM.stop

        assert { last_response.ok? }

        assert { last_response.body.include?('<body id="text">') }
        deny   { last_response.body.include?("<img") }

        title = %{<title>chapter1.txt</title>}
        assert { last_response.body.include?(title) }

        heading = %{<h2>chapter1.txt</h2>}
        assert { last_response.body.include?(heading) }

        link = %{<a class="embed" href="http://cl.ly/hhgttg/chapter1.txt">Direct link</a>}
        assert { last_response.body.include?(link) }

        content = 'The house stood on a slight rise just on the edge of the village.'
        assert { last_response.body.include? content }

        assert_not_cached
      end
    end
  end

  it 'dumps the content of a markdown drop' do
    EM.synchrony do
      VCR.use_cassette 'markdown' do
        get '/hhgttg'
        EM.stop

        assert { last_response.ok? }
        assert { headers['Content-Type'] == 'text/html;charset=utf-8' }

        section_tag = '<section class="monsoon" id="content">'
        assert { last_response.body.include? section_tag }

        content = 'The house stood on a slight rise just on the edge of the village.'
        assert { last_response.body.include? content }

        assert_not_cached
      end
    end
  end

  it 'dumps the content of a typed code drop' do
    EM.synchrony do
      VCR.use_cassette 'ruby' do
        get '/code/hhgttg'
        EM.stop

        assert { last_response.ok? }
        assert { headers['Content-Type'] == 'text/html;charset=utf-8' }

        section_tag = '<section class="monsoon" id="content">'
        assert { last_response.body.include? section_tag }

        content = 'Hello, world!'
        assert { last_response.body.include? content }

        assert_not_cached
      end
    end
  end

  it 'dumps the content of an untyped code drop' do
    EM.synchrony do
      VCR.use_cassette 'ruby' do
        get '/hhgttg'
        EM.stop

        assert { last_response.ok? }
        assert { headers['Content-Type'] == 'text/html;charset=utf-8' }

        section_tag = '<section class="monsoon" id="content">'
        assert { last_response.body.include? section_tag }

        content = 'Hello, world!'
        assert { last_response.body.include? content }

        assert_not_cached
      end
    end
  end

  it 'forwards typed json response' do
    EM.synchrony do
      VCR.use_cassette 'text' do
        header 'Accept', 'application/json'
        get    '/text/hhgttg'
        drop = DropFetcher.fetch 'hhgttg'
        EM.stop

        assert { last_response.ok? }
        assert { headers['Content-Type'] == 'application/json;charset=utf-8' }
        assert { last_response.body == Yajl::Encoder.encode(drop.data) }
        assert_not_cached
      end
    end
  end

  it 'forwards untyped json response' do
    EM.synchrony do
      VCR.use_cassette 'text' do
        header 'Accept', 'application/json'
        get    '/hhgttg'
        drop = DropFetcher.fetch 'hhgttg'
        EM.stop

        assert { last_response.ok? }
        assert { headers['Content-Type'] == 'application/json;charset=utf-8' }
        assert { last_response.body == Yajl::Encoder.encode(drop.data) }
        assert_not_cached
      end
    end
  end

  it 'respects accept header priority' do
    EM.synchrony do
      VCR.use_cassette 'text' do
        header 'Accept', 'text/html,application/json'
        get    '/hhgttg'
        EM.stop

        assert do
          last_response.headers['Content-Type'] == 'text/html;charset=utf-8'
        end
      end
    end
  end

  it 'serves html by default' do
    EM.synchrony do
      VCR.use_cassette 'text' do
        header 'Accept', '*/*'
        get    '/hhgttg'
        EM.stop

        assert do
          last_response.headers['Content-Type'] == 'text/html;charset=utf-8'
        end
      end
    end
  end

  it 'ignores trailing slash' do
    EM.synchrony do
      VCR.use_cassette 'text' do
        get '/hhgttg/'
        EM.stop

        assert { last_response.ok? }
      end
    end
  end

  it 'serves static assets' do
    EM.synchrony do
      get '/images/favicon.ico'
      EM.stop

      assert { headers['Cache-Control'] == "public, max-age=31557600" }
    end
  end
end
