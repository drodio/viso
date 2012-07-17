require 'delegate'
require 'yajl'

class DropPresenter < SimpleDelegator
  def initialize(drop, template)
    @template = template
    super drop
  end

  def render_html
    cache_response

    if bookmark?
      @template.redirect_to_api
    else
      print_debug_message
      @template.erb template_name, layout: layout_name,
                                   locals: { drop: self, body_id: body_id }
    end
  end

  def render_json
    Yajl::Encoder.encode data
  end

private

  def cache_response
    return if text? or pending?
    @template.cache_control :public, :max_age => 900
  end

  def layout_name
    "#{ (beta? || pending?) ? 'new_' : '' }layout".to_sym
  end

  def template_name
    if pending?
      :new_waiting
    elsif image?
      if beta?
        :new_image
      else
        :image
      end
    elsif text?
      if beta?
        :new_markdown
      else
        :text
      end
    else
      if beta?
        :new_download
      else
        :other
      end
    end
  end

  def body_id
    if pending?
      'waiting'
    elsif image?
      'image'
    elsif text?
      'text'
    else
      'other'
    end
  end

  def print_debug_message
    return unless template_name.to_s.start_with?("new_") ||
                    layout_name.to_s.start_with?("new_")

    debug = { template: template_name, layout: layout_name }
    puts [ '#' * 5, "rendering #{ debug.inspect }", '#' * 5 ].join(' ')
  end
end
