# Copyright (c) 2009-2012 VMware, Inc.

require "vcap/component"
require "steno"

module Sinatra
  module VCAP

    def self.registered(app)
    end

    def vcap_configure(opts = {})
      configure do
        set(:show_exceptions, false)
        set(:raise_errors, false)
        set(:dump_errors, false)
      end

      before do
        logger_name = opts[:logger_name] || "uhuru-cloud-commander.runner"
        env["rack.logger"] = Steno.logger(logger_name)
      end

      after do
        nil
      end
    end

  end

  register VCAP
end