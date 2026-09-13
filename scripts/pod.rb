# Load the locked logger before ActiveSupport 6, which does not require it itself.
require 'bundler/setup'
require 'logger'
load Gem.bin_path('cocoapods', 'pod')
