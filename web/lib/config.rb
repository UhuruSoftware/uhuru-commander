require 'logger'
require 'vcap/config'

module Uhuru
  module Ucc
  end

end

class Uhuru::Ucc::Config < VCAP::Config
  DEFAULT_CONFIG_PATH = File.expand_path('../../uhuru-cloud-commander.yml', __FILE__)
  define_schema do
    {
        :bosh => {
            :target => String
        }
    }
  end

  def self.from_file(*args)
    config = super(*args)
    config
  end

end