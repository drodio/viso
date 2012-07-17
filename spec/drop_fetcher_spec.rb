require 'support/vcr'
require 'drop_fetcher'

describe DropFetcher do
  describe '.base_uri' do
    it 'defaults to api.cld.me' do
      DropFetcher.base_uri.should eq('api.cld.me')
    end

    context 'overriding' do
      let(:overridden) { 'override.com' }
      before do
        @original_base_uri = DropFetcher.base_uri
        ENV['CLOUDAPP_DOMAIN'] = overridden
        load 'lib/drop_fetcher.rb'
      end

      after do
        ENV['CLOUDAPP_DOMAIN'] = @original_base_uri
        load 'lib/drop_fetcher.rb'
      end

      it 'is overridden' do
        DropFetcher.base_uri.should eq(overridden)
      end
    end
  end

  describe '.default_domains' do
    it 'defaults to cl.ly domains' do
      DropFetcher.default_domains.should eq(%w( cl.ly www.cl.ly ))
    end

    context 'overriding' do
      let(:overridden) { 'override.com www.override.com' }
      before do
        @original_default_domains = DropFetcher.default_domains.join(' ')
        ENV['DEFAULT_DOMAINS'] = overridden
        load 'lib/drop_fetcher.rb'
      end

      after do
        ENV['DEFAULT_DOMAINS'] = @original_default_domains
        load 'lib/drop_fetcher.rb'
      end

      it 'is overridden' do
        DropFetcher.default_domains.
          should eq(%w( override.com www.override.com ))
      end
    end
  end

  describe '.fetch' do
    it 'returns a drop' do
      EM.synchrony do
        VCR.use_cassette 'bookmark' do
          drop = DropFetcher.fetch 'hhgttg'
          EM.stop

          drop.should be_a(Drop)
        end
      end
    end

    it 'symbolizes keys' do
      Drop.should_receive(:new).with(hash_including(:content_url))

      EM.synchrony do
        VCR.use_cassette 'bookmark' do
          DropFetcher.fetch 'hhgttg'
          EM.stop
        end
      end
    end

    it 'raises a DropNotFound error' do
      EM.synchrony do
        VCR.use_cassette 'nonexistent' do
          lambda { DropFetcher.fetch 'hhgttg' }.
            should raise_error(DropFetcher::NotFound)

          EM.stop
        end
      end
    end
  end
end
