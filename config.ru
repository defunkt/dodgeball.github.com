require "rubygems"
require "bundler"

Bundler.setup
Bundler.require(:runtime)

require './dodgeball'

use Rack::Static, :urls => ["/css", "/images", "/fonts", "/shared"], :root => "public"

run Dodgeball

