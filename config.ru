require 'rubygems'
require 'bundler'
Bundler.require(:default)

require File.expand_path('./app', File.dirname(__FILE__))

# HTTP config
use Rack::Lint
use Rack::Chunked
use Rack::Deflater
use Rack::Cache,
    verbose: false,
    metastore: 'heap:/',
    entitystore: 'heap:/'

run WSApp::App.new
