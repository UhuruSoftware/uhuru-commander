

class SpecHelper
  def self.bosh_login
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
end