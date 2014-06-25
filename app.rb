$stdout.sync = true
require 'sinatra/base'
require 'sinatra/cross_origin'
require 'sinatra/config_file'
require 'sinatra/namespace'
require 'sinatra/reloader'

require 'rest-client'
require 'xmlsimple'
require 'savon'
require 'logger'
require 'json'

require_relative 'wsapp_helpers'

module WSApp

  class App < Sinatra::Base
    register Sinatra::ConfigFile
    register Sinatra::CrossOrigin
    register Sinatra::Namespace

    set :environments, %w(production development test)
    set :environment, (ENV['RACK_ENV'] || ENV['WSAPP_APPLICATION_ENV'] || :development).to_sym

    set :allow_origin, :any
    set :allow_methods, %w(:get)
    set :expose_headers, %w(Content-Type)

    config_file 'config_file.yml'

    configure do
      enable :logging
      enable :cross_origin
      set :soap_client, Savon.client(wsdl: 'http://localhost/workspace/github/ws-soap-server/SoapServer.php?wsdl')
      set :rest_server, 'http://localhost:3000'
    end

    configure :production do
      set :logging, Logger::INFO
    end

    configure :development do
      register Sinatra::Reloader
    end

    configure %w(development test) do
      set :logging, Logger::DEBUG
    end

    helpers do
      include WSApp::Helpers
    end

    get '/' do
      json_response 200, { data: { hello: 'world' } }
    end


    # Places

    get '/places' do
      url = "#{settings.rest_server}/places"
      url << "?f=#{params['f']}" unless params['f'].nil?
      response = RestClient.get url, { accept: :xml }
      conversions = {
        /^town_id|id/         => lambda { |v| v.to_i },
        /^latitude|longitude/ => lambda { |v| v.to_f }
      }
      to_xml = XmlSimple.xml_in response.to_str, conversions: conversions, forcearray: false
      rendered = to_xml['places']['place']
      rendered = [rendered] unless rendered.kind_of? Array
      json_response 200, { data: rendered }
    end

    get '/places/:id' do
      url = "#{settings.rest_server}/places/#{params['id'].to_i}"
      response = RestClient.get url, { accept: :xml }
      conversions = {
        /^town_id|id/         => lambda { |v| v.to_i },
        /^latitude|longitude/ => lambda { |v| v.to_f }
      }
      to_xml = XmlSimple.xml_in response.to_str, conversions: conversions, forcearray: false
      json_response 200, { data: to_xml['places']['place'] }
    end

    post '/places' do
      url = "#{settings.rest_server}/places"
      response = RestClient.post url, to_xml(params[:place]), content_type: :xml, accept: :xml
      conversions = { /^placeId/ => lambda { |v| v.to_i } }
      from_xml = from_xml response.to_str, conversions
      json_response 201, { data: { place_id: from_xml['placeId'] } }
    end

    get '/places/:id/comments' do
      place_id = params[:id].to_i
      response = settings.soap_client.call(:get_comments_by_parent_id, message: { idParent: place_id })
      results = response.body[:get_comments_by_parent_id_response][:return]
      comments = reformat_soap_results(results)
      comments = [comments] unless comments.kind_of? Array
      json_response 200, { data: comments }
    end

    post '/places/:id/comments' do
      place_id = params[:id].to_i
      comment_params = params[:comment]
      comment = {
        id: random_id,
        idParent: place_id,
        author: comment_params[:author],
        mark: comment_params[:mark].to_i,
        text: comment_params[:text]
      }
      settings.soap_client.call(:add_comment, message: comment)
      comment.reject! { |k| k == :idParent }
      comment[:place_id] = place_id
      json_response 201, { data: comment }
    end


    # Towns

    get '/towns' do
      response = RestClient.get "#{settings.rest_server}/towns", { accept: :xml }
      conversions = { /^country_id|id|population/ => lambda { |v| v.to_i } }
      to_xml = XmlSimple.xml_in response.to_str, conversions: conversions, forcearray: false
      json_response 200, { data: to_xml['towns']['town'] }
    end

    get '/towns/:id' do
      url = "#{settings.rest_server}/towns/#{params['id'].to_i}"
      response = RestClient.get url, { accept: :xml }
      conversions = { /^country_id|id|population/ => lambda { |v| v.to_i } }
      to_xml = XmlSimple.xml_in response.to_str, conversions: conversions, forcearray: false
      json_response 200, { data: to_xml['towns']['town'] }
    end

    post '/towns' do
      url = "#{settings.rest_server}/towns"
      response = RestClient.post url, to_xml(params[:town]), content_type: :xml, accept: :xml
      conversions = { /^townId/ => lambda { |v| v.to_i } }
      from_xml = from_xml response.to_str, conversions
      json_response 201, { data: { town_id: from_xml['townId'] } }
    end


    # Countries

    get '/countries' do
      response = RestClient.get "#{settings.rest_server}/countries", { accept: :xml }
      conversions = { /^id/ => lambda { |v| v.to_i } }
      to_xml = XmlSimple.xml_in response.to_str, conversions: conversions, forcearray: false
      json_response 200, { data: to_xml['countries']['country'] }
    end

    get '/countries/:id' do
      url = "#{settings.rest_server}/countries/#{params['id'].to_i}"
      response = RestClient.get url, { accept: :xml }
      conversions = { /^id/ => lambda { |v| v.to_i } }
      to_xml = XmlSimple.xml_in response.to_str, conversions: conversions, forcearray: false
      json_response 200, { data: to_xml['countries']['country'] }
    end

    post '/countries' do
      url = "#{settings.rest_server}/countries"
      response = RestClient.post url, to_xml(params[:country]), content_type: :xml, accept: :xml
      conversions = { /^countryId/ => lambda { |v| v.to_i } }
      from_xml = from_xml response.to_str, conversions
      json_response 201, { data: { country_id: from_xml['countryId'] } }
    end



    get '/test-xml' do
      content_type 'text/xml'
      XmlSimple.xml_out({place: {id: 1}},
                        'AttrPrefix' => true,
                        'KeyAttr' => ['name', 'key', 'id'],
                        'XmlDeclaration' => true)
    end

    not_found do
      json_response 404, { error: 'Not found' }
    end
  end

end
