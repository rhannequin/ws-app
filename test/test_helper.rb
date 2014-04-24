ENV['RACK_ENV'] = 'test'

require 'test/unit'
require 'rack/test'
require_relative '../app'
require_relative '../wsapp_helpers'

class Test::Unit::TestCase
  include Rack::Test::Methods
  include WSApp::Helpers

  def app
    WSApp::App
  end
end
