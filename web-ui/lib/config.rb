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

  def self.symbolize_hash(hash)
    hash.keys.each do |key|
      sym    = key.to_sym
      hash[sym] = hash.delete key
      if hash[hash].kind_of? Hash
        symbolize_hash! hash[sym]
      end
    end
    hash
  end
end