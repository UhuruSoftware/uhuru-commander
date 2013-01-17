require "config"
require "steno"
require "thin"

module Uhuru::Ucc
  class Runner
    def initialize(argv)
      @argv = argv

      @config_file = File.expand_path("../../config/uhuru-cloud-commander.yml", __FILE__)

      setup_logging
    end

    def logger
      @logger ||= Steno.logger("uhuru-cloud-commander.runner")
    end

    def setup_logging
      steno_config = Steno::Config.to_config_hash($config[:logging])
      steno_config[:context] = Steno::Context::ThreadLocal.new
      Steno.init(Steno::Config.new(steno_config))
    end

    def run!
      config = $config.dup
      app = Rack::Builder.new do
        # TODO: we really should put these bootstrapping into a place other
        # than Rack::Builder
        use Rack::CommonLogger
        use Rack::Recaptcha, :public_key => config[:ui_settings][:recaptcha_public_key], :private_key => config[:ui_settings][:recaptcha_private_key]

        map "/" do
          run Uhuru::SimpleWebui::SimpleWebui.new()
        end
      end
      @thin_server = Thin::Server.new($config[:bind_address], $config[:port])
      @thin_server.app = app

      trap_signals

      @thin_server.threaded = true
      @thin_server.start!
    end

    def trap_signals
      ["TERM", "INT"].each do |signal|
        trap(signal) do
          @thin_server.stop! if @thin_server
          EM.stop
        end
      end
    end
  end
end