# Viso
# ------
#
# **Viso** is the magic that powers [CloudApp][] by displaying shared Drops. At
# its core, **Viso** is a simple [Sinatra][] app that retrieves a **Drop's**
# details using the [CloudApp API][]. Images are displayed front and center,
# bookmarks are redirected to their destination, markdown is processed by
# [RedCarpet][], code files are highlighted by [Pygments], and, when all else
# fails, a download button is provided. **Viso** uses [eventmachine][] and
# [rack-fiber_pool][] to serve requests while expensive network I/O is performed
# asynchronously.
#
# [cloudapp]:        http://getcloudapp.com
# [sinatra]:         https://github.com/sinatra/sinatra
# [cloudapp api]:    http://developer.getcloudapp.com
# [redcarpet]:       https://github.com/tanoku/redcarpet
# [pygments]:        http://pygments.org
# [eventmachine]:    https://github.com/eventmachine/eventmachine
# [rack-fiber_pool]: https://github.com/mperham/rack-fiber_pool
require 'addressable/uri'
require 'eventmachine'
require 'metriks'
require 'sinatra/base'
require 'simpleidn'

require 'configuration'
require 'drop'
require 'drop_fetcher'
require 'drop_presenter'
require 'domain'
require 'domain_fetcher'

class Viso < Sinatra::Base

  register Configuration

  # The home page. Custom domain users have the option to set a home page so
  # ping the API to get the home page for the current domain. Response is cached
  # for one hour.
  get '/' do
    cache_control :public, :max_age => 3600
    redirect DomainFetcher.fetch(env['HTTP_HOST']).home_page
  end

  # The main responder for a **Drop**. Responds to both JSON and HTML and
  # response is cached for 15 minutes.
  get %r{^                         #
         (?:/(text|code|image))?   # Optional drop type
         /([^/?#]+)                # Item slug
         (?:                       #
           /  |                    # Ignore trailing /
           /o                      # Show original image size
         )?                        #
         $}x do |type, slug|
    Metriks.timer('viso.drop').time {
      fetch_and_render_drop slug
    }
  end

  get %r{^
         /([^/?#]+)  # Item slug
         /status
         $}x do |slug|
    fetch_and_render_status slug
  end

  # The content for a **Drop**. Redirect to the identical path on the API domain
  # where the view counter is incremented and the visitor is redirected to the
  # actual URL of file. Response is cached for 15 minutes.
  get %r{^
         /([^/?#]+)  # Item slug
         /(.+)       # Filename
         $}x do |slug, filename|
    cache_control :public, :max_age => 900
    redirect_to_api
  end

  # Don't need to return anything special for a 404.
  not_found do
    not_found error_content_for(:not_found)
  end

  # Redirect the current request to the same path on the API domain.
  def redirect_to_api
    redirect "http://#{ DropFetcher.base_uri }#{ request.path }"
  end


protected

  # Fetch and return a **Drop** with the given `slug`. Handle
  # `DropFetcher::NotFound` errors and render the not found response.
  def fetch_drop(slug)
    DropFetcher.fetch slug
  rescue DropFetcher::NotFound
    not_found
  end

  def fetch_and_render_drop(slug)
    drop = Metriks.timer('viso.drop.fetch').time {
      drop = DropPresenter.new fetch_drop(slug), self
    }

    check_domain_matches drop

    Metriks.timer("viso.drop.render.#{ drop.item_type }").time {
      respond_to {|format|
        format.html { drop.render_html }
        format.json { drop.render_json }
      }
    }
  rescue => e
    env['async.callback'].call [ 500, {}, error_content_for(:error) ]
    Airbrake.notify_or_ignore e if defined? Airbrake
  end

  def fetch_and_render_status(slug)
    puts [ '#' * 5, 'rendering status', '#' * 5 ].join(' ')
    drop = DropPresenter.new fetch_drop(slug), self
    status drop.pending? ? 204 : 200
  end

  def error_content_for(type)
    type = type.to_s.gsub /_/, '-'
    File.read File.join(settings.public_folder, "#{ type }.html")
  end

  # Check for drops served where the drop's domain doesn't match the accessed
  # domain. For example, a user using another user's custom domain.
  def check_domain_matches(drop)
    unless custom_domain_matches? drop
      puts [ '*' * 5,
             drop.data[:url].inspect,
             env['HTTP_HOST'].inspect,
             '*' * 5
           ].join(' ')

      not_found
    end
  end

  def custom_domain_matches?(drop)
    expected = SimpleIDN.to_ascii Addressable::URI.parse(drop.data[:url]).host
    actual   = SimpleIDN.to_ascii env['HTTP_HOST'].split(':').first

    DropFetcher.default_domains.include?(actual) or
      actual == expected or
      actual.sub(/^www\./, '') == expected
  end

end
