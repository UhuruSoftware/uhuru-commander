
require "rspec"
require "rack/test"

$:.unshift(File.expand_path("../../lib", __FILE__))
require "versioning/product"
require "runner"
require "ucc/stemcell"
require "ucc/commander_bosh_runner"


def bosh_login
  session = {}

  command = Bosh::Cli::Command::Misc.new
  session[:command] = command

  tmpdir = Dir.mktmpdir

  config = File.join(tmpdir, "bosh_config")
  cache = File.join(tmpdir, "bosh_cache")

  command.add_option(:config, config)
  command.add_option(:cache_dir, cache)
  command.add_option(:non_interactive, true)

  Uhuru::BoshCommander::CommanderBoshRunner.execute(session) do
    Bosh::Cli::Config.cache = Bosh::Cli::Cache.new(cache)
    command.set_target($config[:bosh][:target])
    command.login('admin', 'admin')
  end

  session
end

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end

def get_browser
  Rack::Test::Session.new(Rack::MockSession.new(Sinatra::Application))
end

