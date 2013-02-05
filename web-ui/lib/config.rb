require "vcap/config"

module Uhuru
  module BoshCommander
  end
end

class Uhuru::BoshCommander::Config < VCAP::Config
  DEFAULT_CONFIG_PATH = File.expand_path('../../config.yml', __FILE__)


  define_schema do
    {
        :bosh_commander =>{
            :domain => String
        }
    }
  end

  def self.from_file(*args)
    config = super(*args)
    config
  end
end