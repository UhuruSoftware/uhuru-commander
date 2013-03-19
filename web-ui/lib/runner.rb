require 'rack/reverse_proxy'
require "steno"
require "config"
require "boshcommander"
require "thin"
require 'optparse'
require "../lib/ucc/status_streamer"

module Uhuru::BoshCommander
  class Runner
    def initialize(argv)
      @argv = argv

      # default to production. this may be overriden during opts parsing
      ENV["RACK_ENV"] = "production"
      # default config path. this may be overriden during opts parsing
      @config_file = File.expand_path("../../config/config.yml", __FILE__)

      parse_options!

      $config = Uhuru::BoshCommander::Config.from_file(@config_file)
      $config[:bind_address] = VCAP.local_ip($config[:local_route])

      create_pidfile
      setup_logging
      $config[:logger] = logger
    end

    def logger
      @logger ||= Steno.logger("uhuru-cloud-commander.runner")
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
        pid_file = VCAP::PidFile.new($config[:pid_filename])
        pid_file.unlink_at_exit
      rescue => e
        puts "ERROR: Can't create pid file #{$config[:pid_filename]}"
        exit 1
      end
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
        use Rack::Session::Pool

        use Rack::ReverseProxy do
          # Set :preserve_host to true globally (default is true already)
          reverse_proxy_options :preserve_host => true

          # Forward the path /test* to http://example.com/test*

          tty_js_location = "http://#{$config[:ttyjs][:host]}:#{$config[:ttyjs][:port]}"

          reverse_proxy "/user.js", "#{tty_js_location}/user.js"
          reverse_proxy "/user.css", "#{tty_js_location}/user.css"
          reverse_proxy "/style.css", "#{tty_js_location}/style.css"
          reverse_proxy "/tty.js", "#{tty_js_location}/tty.js"
          reverse_proxy "/term.js", "#{tty_js_location}/term.js"
          reverse_proxy "/options.js", "#{tty_js_location}/options.js"
          reverse_proxy '/socket.io', "#{tty_js_location}/"
          reverse_proxy /^\/ssh(\/.*)$/, "#{tty_js_location}/$1"
        end

        map "/" do
          run Uhuru::BoshCommander::BoshCommander
        end
      end
      @thin_server = Thin::Server.new('0.0.0.0', $config[:port])
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
