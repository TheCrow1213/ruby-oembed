require File.dirname(__FILE__) + '/spec_helper'
require 'vcr'

VCR.config do |c|
  c.default_cassette_options = { :record => :new_episodes }
  c.cassette_library_dir = 'spec/cassettes'
  c.stub_with :fakeweb
end

describe OEmbed::ProviderDiscovery do
  before(:all) do
    VCR.insert_cassette('OEmbed_ProviderDiscovery')
  end
  after(:all) do
    VCR.eject_cassette
  end

  include OEmbedSpecHelper

  {
    'youtube' => [
      'http://www.youtube.com/watch?v=u6XAPnuFjJc',
      'http://www.youtube.com/oembed',
      :json,
    ],
    'vimeo' => [
      'http://vimeo.com/27953845',
      {:json=>'http://vimeo.com/api/oembed.json',:xml=>'http://vimeo.com/api/oembed.xml'},
      :json,
    ],
    #'noteflight' => [
    #  'http://www.noteflight.com/scores/view/09665392c94475f65dfaf5f30aadb6ed0921939d',
    #  'http://www.noteflight.com/services/oembed',
    #  :json,
    #],
    #'wordpress' => [
    #  'http://sweetandweak.wordpress.com/2011/09/23/nothing-starts-the-morning-like-a-good-dose-of-panic/',
    #  'http://public-api.wordpress.com/oembed/1.0/',
    #  :json,
    #],
  }.each do |context, urls|

    given_url, expected_endpoint, expected_format = urls

    context "with #{context} url" do

      describe "discover_provider" do

        before(:all) do
          @provider_default = OEmbed::ProviderDiscovery.discover_provider(given_url)
          @provider_json = OEmbed::ProviderDiscovery.discover_provider(given_url, :format=>:json)
          @provider_xml = OEmbed::ProviderDiscovery.discover_provider(given_url, :format=>:xml)
        end

        it "should return the correct Class" do
          expect(@provider_default).to be_instance_of(OEmbed::Provider)
          expect(@provider_json).to be_instance_of(OEmbed::Provider)
          expect(@provider_xml).to be_instance_of(OEmbed::Provider)
        end

        it "should detect the correct URL" do
          if expected_endpoint.is_a?(Hash)
            expect(@provider_json.endpoint).to eq(expected_endpoint[expected_format])
            expect(@provider_json.endpoint).to eq(expected_endpoint[:json])
            expect(@provider_xml.endpoint).to eq(expected_endpoint[:xml])
          else
            expect(@provider_default.endpoint).to eq(expected_endpoint)
            expect(@provider_json.endpoint).to eq(expected_endpoint)
            expect(@provider_xml.endpoint).to eq(expected_endpoint)
          end
        end

        it "should return the correct format" do
          expect(@provider_default.format).to eq(expected_format)
          expect(@provider_json.format).to eq(:json)
          expect(@provider_xml.format).to eq(:xml)
        end
      end # discover_provider

      describe "get" do

        before(:all) do
          @response_default = OEmbed::ProviderDiscovery.get(given_url)
          @response_json = OEmbed::ProviderDiscovery.get(given_url, :format=>:json)
          @response_xml = OEmbed::ProviderDiscovery.get(given_url, :format=>:xml)
        end

        it "should return the correct Class" do
          expect(@response_default).to be_kind_of(OEmbed::Response)
          expect(@response_json).to be_kind_of(OEmbed::Response)
          expect(@response_xml).to be_kind_of(OEmbed::Response)
        end

        it "should return the correct format" do
          expect(@response_default.format).to eq(expected_format.to_s)
          expect(@response_json.format).to eq('json')
          expect(@response_xml.format).to eq('xml')
        end

        it "should return the correct data" do
          expect(@response_default.type).to_not be_nil
          expect(@response_json.type).to_not be_nil
          expect(@response_xml.type).to_not be_nil

          # Technically, the following values _could_ be blank, but for the
          # examples urls we're using we expect them not to be.
          expect(@response_default.title).to_not be_nil
          expect(@response_json.title).to_not be_nil
          expect(@response_xml.title).to_not be_nil
        end
      end # get
    end

  end # each service

  context "when returning 404" do
    let(:url) { 'https://www.youtube.com/watch?v=123123123' }

    it "raises OEmbed::NotFound" do
      expect{ OEmbed::ProviderDiscovery.discover_provider(url) }.to raise_error(OEmbed::NotFound)
    end
  end

  context "when returning 301" do
    let(:url) { 'http://www.youtube.com/watch?v=dFs9WO2B8uI' }

    it "does redirect http to https" do
      expect{ OEmbed::ProviderDiscovery.discover_provider(url) }.not_to raise_error
    end
  end

  it "does passes the timeout option to Net::Http" do
    expect_any_instance_of(Net::HTTP).to receive(:open_timeout=).with(5)
    expect_any_instance_of(Net::HTTP).to receive(:read_timeout=).with(5)
    OEmbed::ProviderDiscovery.discover_provider('https://www.youtube.com/watch?v=dFs9WO2B8uI', :timeout => 5)
  end
end
