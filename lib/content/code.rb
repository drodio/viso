require 'metriks'
require 'rubypython'
require 'pygments.rb'

class Content
  module Code
    include Pygments

    # Heroku's cedar stack raises an "invalid ELF header" exception using the
    # latest version of python (2.7) on the system. python2.6 seems to work fine.
    RubyPython.configure :python_exe => 'python2.6'

    def self.highlight(code, lexer)
      Metriks.timer('viso.pygments').time {
        Pygments.highlight code, lexer: lexer, options: { encoding: 'utf-8' }
      }
    end

    def content
      return super unless code?
      return large_content if code_too_large?

      Code.highlight raw, lexer_name
    end

    def code?
      lexer_name && !%w( text postscript minid ).include?(lexer_name)
    end

    def lexer_name
      @timer = Metriks.timer('viso.pygments.lexer_name').time
      @lexer_name ||= lexer_name_for :filename => @content_url
    rescue RubyPython::PythonError
      false
    ensure
      @timer.stop
    end

    def code_too_large?
      raw.size >= 50_000
    end

    def large_content
      %{<div class="highlight"><pre><code>#{ escaped_raw }</code></pre></div>}
    end
  end
end
