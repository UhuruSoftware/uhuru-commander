require "vcap/config"

module Uhuru
  module BoshCommander
  end
end

# The class that manages config.yml config file
class Uhuru::BoshCommander::Config < VCAP::Config
  DEFAULT_CONFIG_PATH = File.expand_path('../../config.yml', __FILE__)


  define_schema do
    {
        :bosh_commander =>{
            :domain => String
        }
    }
  end

  # Loads settings from a file to a Hash validating the file schema
  # *args = filename, symbolize_keys=true
  #
  def self.from_file(*args)
    config = super(*args)
    config
  end

  # Transforms keys of a hash from string to symbol
  # hash = the hash containing the keys
  #
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