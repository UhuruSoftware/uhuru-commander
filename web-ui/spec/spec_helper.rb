
require "rspec"
require "rack/test"

$:.unshift(File.expand_path("../../lib", __FILE__))
require "versioning/product"
require "runner"
require "ucc/stemcell"
require "ucc/commander_bosh_runner"



def load_config
  @config_file = File.expand_path("../../config/config_dev.yml", __FILE__)
  Uhuru::BoshCommander::Runner.init_config @config_file

  $config[:versioning][:blobstore_provider] = "local"
  $config[:versioning][:blobstore_options] = {:blobstore_path => File.expand_path("../assets/dummy_blobstore/", __FILE__)}

end

def session
  {:command =>  Uhuru::BoshCommander::MockBoshCommand.new}
end

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end

def get_browser
  Rack::Test::Session.new(Rack::MockSession.new(Sinatra::Application))
end

