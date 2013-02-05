#require "steno"
require "config"
require "boshcommander"
require "thin"

module Uhuru::BoshCommander
  class Runner
    def initialize(argv)
      @argv = argv

      # default to production. this may be overriden during opts parsing
      ENV["RACK_ENV"] = "production"
      # default config path. this may be overriden during opts parsing
      @config_file = File.expand_path("../../config/config.yml", __FILE__)

      parse_options!

      @config = Uhuru::BoshCommander::Config.from_file(@config_file)
      @config[:bind_address] = VCAP.local_ip(@config[:local_route])

      create_pidfile
    end

    def options_parser
      @parser ||= OptionParser.new do |opts|
        opts.on("-c", "--config [ARG]", "Configuration File") do |opt|
          @config_file = opt
        end

        opts.on("-d", "--development-mode", "Run in development mode") do
          # this must happen before requring any modules that use sinatra,
          # otherwise it will not setup the environment correctly
          @development = true
          ENV["RACK_ENV"] = "development"
        end
      end
    end

    def parse_options!
      options_parser.parse! @argv
    rescue
      puts options_parser
      exit 1
    end

    def create_pidfile
      begin
        pid_file = VCAP::PidFile.new(@config[:pid_filename])
        pid_file.unlink_at_exit
      rescue => e
        puts "ERROR: Can't create pid file #{@config[:pid_filename]}"
        exit 1
      end
    end

    def run!
      config = @config.dup

      app = Rack::Builder.new do
        # TODO: we really should put these bootstrapping into a place other
        # than Rack::Builder
        use Rack::CommonLogger

        map "/" do
          run Uhuru::BoshCommander::BoshCommander.new(config)
        end
      end
      @thin_server = Thin::Server.new(@config[:bind_address], @config[:port])
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
