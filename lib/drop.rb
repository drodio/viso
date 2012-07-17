require 'content'
require 'forwardable'

class Drop
  extend Forwardable

  attr_accessor :data

  def initialize(data)
    @data    = data
    @content = Content.new content_url
  end

  def_delegators :@content, :content, :markdown?, :code?

  def subscribed?()  @data[:subscribed]   end
  def item_type()    @data[:item_type]    end
  def content_url()  @data[:content_url]  end
  def download_url() @data[:download_url] end
  def name()         @data[:name]         end
  def gauge_id()     @data[:gauge_id]     end

  def bookmark?
    @data[:item_type] == 'bookmark'
  end

  def beta?
    source = @data.fetch :source, nil
    source && source.include?('Cloud/2.0 beta')
  end

  def image?
    %w( .bmp
        .gif
        .ico
        .jp2
        .jpe
        .jpeg
        .jpf
        .jpg
        .jpg2
        .jpgm
        .png ).include? extension
  end

  def plain_text?
    extension == '.txt'
  end

  def text?
    plain_text? || markdown? || code?
  end

  def pending?
    item_type.nil?
  end

  def basename
    basename = File.basename(name.to_s, File.extname(name.to_s))
    basename.empty? ? nil : basename
  end

  def extension
    extname = File.extname(file_name).downcase
    extname.empty? ? nil : extname
  end

private

  def file_name
    file_name = pending? ? name : content_url
    file_name.to_s
  end
end
