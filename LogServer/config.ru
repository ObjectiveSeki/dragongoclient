require 'bundler'
Bundler.setup

$: << File.expand_path('lib', File.dirname(__FILE__))

require 'log_server'
run LogServer
