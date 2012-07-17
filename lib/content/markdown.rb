require 'metriks'
require 'redcarpet'

class Content
  module Markdown
    def content
      return super unless markdown?
      Metriks.timer('viso.markdown').time {
        Redcarpet::Markdown.new(PygmentizedHTML,
                                fenced_code_blocks: true).render(raw)
      }
    end

    def markdown?
      %w( .md
          .mdown
          .markdown ).include? extension
    end

  private

    def extension
      File.extname(@content_url).downcase
    end
  end

  # TODO: This is just a spike.
  class PygmentizedHTML < Redcarpet::Render::HTML
    def block_code(code, language)
      Content::Code.highlight code, language
    end
  end
end
