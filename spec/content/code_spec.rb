# encoding: utf-8
require 'content/code'

describe Content::Code do
  before do
    module FakeSuper
      def content
        'super content'
      end
    end

    class FakeContent
      include FakeSuper
      include Content::Code

      def initialize(content_url)
        @content_url = content_url
      end

      def raw
        "puts 'Hello, world!'"
      end
      alias_method :escaped_raw, :raw
    end
  end

  after do
    Object.send :remove_const, :FakeContent
    Object.send :remove_const, :FakeSuper
  end


  describe '#content' do
    it 'syntax highlights content' do
      drop = FakeContent.new 'http://cl.ly/hhgttg/hello.rb'
      code = '<div class="highlight"><pre><span class="nb">puts</span>'

      drop.content.should include(code)
    end

    it 'calls #super for non-code files' do
      drop = FakeContent.new 'http://cl.ly/hhgttg/chapter1.txt'

      drop.content.should == 'super content'
    end

    it "doesn't highlight large code files" do
      code     = "puts 123\n" * 5_556
      expected = %{<div class="highlight"><pre><code>#{ code }</code></pre></div>}

      drop = FakeContent.new 'http://cl.ly/hhgttg/hello.rb'
      drop.stub! :raw => code, :escaped_raw => code

      drop.content.should == expected
    end

    it 'escapes html in large code files' do
      code     = "puts 123\n" * 5_556
      escaped  = 'escaped'
      expected = %{<div class="highlight"><pre><code>#{ escaped }</code></pre></div>}

      drop = FakeContent.new 'http://cl.ly/hhgttg/hello.rb'
      drop.stub! :raw => code, :escaped_raw => escaped

      drop.content.should == expected
    end

    it "handles utf-8 characters" do
      code     = '☃'
      expected = %{<div class="highlight"><pre><code>#{ code }</code></pre></div>}

      drop = FakeContent.new 'http://cl.ly/hhgttg/hello.rb'
      drop.stub! :raw => code, :escaped_raw => code

      drop.content.should include(code)
    end
  end

  describe '#code?' do
    it 'is true when a ruby file' do
      drop = FakeContent.new 'http://cl.ly/hhgttg/hello.rb'

      drop.should be_code
    end

    it 'is false when an image' do
      drop = FakeContent.new 'http://cl.ly/hhgttg/cover.png'

      drop.should_not be_code
    end

    %w( ps md txt ).each do |ext|
      it "is false when a #{ ext.upcase } file" do
        drop = FakeContent.new "http://cl.ly/hhgttg/chapter1.#{ ext }"

        drop.should_not be_code
      end
    end
  end
end
