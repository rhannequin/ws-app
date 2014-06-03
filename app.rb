$stdout.sync = true
require 'sinatra/base'
require 'sinatra/cross_origin'
require 'sinatra/config_file'
require 'sinatra/namespace'
require 'sinatra/reloader'
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
      set :soap_client, Savon.client(wsdl: 'http://localhost/workspace/github/ws-soap-server/comments.wsdl')
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

    get '/test-xml' do
      content_type 'text/xml'
      XmlSimple.xml_out({place: {id: 1}},
                        'AttrPrefix' => true,
                        'KeyAttr' => ['name', 'key', 'id'],
                        'XmlDeclaration' => true)
    end

    get '/places/:id/comments' do
      place_id = params[:id].to_i
      response = settings.soap_client.call(:get_comments_by_parent_id, message: { id: place_id })
      results = response.body[:get_comments_by_parent_id_response][:return]
      json_response 200, { data: { results: reformat_soap_results(results) } }
    end

    not_found do
      json_response 404, { error: 'Not found' }
    end
  end

end
