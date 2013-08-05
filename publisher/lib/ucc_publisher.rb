require 'bundler/setup'
require 'rubygems'
require 'sinatra'
require 'yaml'
require 'securerandom'

require 'escort'
require 'terminal-table'
require 'blobstore_client'

require 'client'
require 'products'
require 'versions'
require 'web_controller'
require 'web_modal'


if defined?(YAML::ENGINE.yamler)
  YAML::ENGINE.yamler = RUBY_VERSION >= "2.0.0" ? "psych" : "syck"
end

module Uhuru
  module UCC
    module Publisher

    BLOBSTORE_ID_PRODUCTS = "products.yml"

      class Main

        Escort::App.create do |app|

          app.version "0.9"

          #app.options do |opts|
          #  opts.opt :config, "Configuration file", :short => "-c", :long => "--config", :type => :string
          #  opts.validate(:config, "file does not exist") {|config| File.exists?(config)}
          #end
          app.command :products do |command|
            command.summary "Display products"
            command.description "Display all available products"
            command.action do |options, arguments|
              Uhuru::UCC::Publisher::Products.new(options, arguments).products
            end
          end

          app.command :product do |command|
            command.summary "Display product info"
            command.options do |opts|
              opts.opt :name,         "Product name",             :short => "-n", :long => "--name",                :type => :string
              opts.opt :prod_version, "Product version",          :short => "-r", :long => "--release_version",     :type => :string,   :default => "all"
            end

            command.action do |options, arguments|
              Uhuru::UCC::Publisher::Products.new(options, arguments).product
            end
          end

          app.command :add do |command|
            command.summary "[product, dependency]"

            command.command :product do |add_product|
              add_product.summary "Add product"
              add_product.description "Add a new product"
              add_product.options do |opts|
                opts.opt :name,         "Product name",                         :short => "-n", :long => "--name",        :type => :string
                opts.opt :label,        "Product label",                        :short => "-l", :long => "--label",       :type => :string
                opts.opt :description,  "Product description",                  :short => "-d", :long => "--description", :type => :string
                opts.opt :type,         "Product type [ucc, software, stemcell]",         :short => "-t", :long => "--type",        :type => :string
                opts.opt :force,        "Force overwrite",                      :short => :none, :long => "--force",       :type => :boolean, :default => false
                opts.opt :blob_id,      "Overwrtire blobstore ID",              :short => "-b", :long => "--blob",        :type => :string,  :default => SecureRandom.hex.to_s

                opts.validate(:type, "must be one of the following: [ucc, software, stemcell]") {|option| ["ucc", "software", "stemcell"].include?(option) }

                opts.dependency :blob_id, :on => [{:force => false}]
              end
              add_product.action do |options, arguments|
                Uhuru::UCC::Publisher::Products.new(options, arguments).add_product
              end
            end

            command.command :dependency do |add_dependency|
              add_dependency.summary "Add dependency"
              add_dependency.description "Add dependency between product versions"
              add_dependency.options do |opts|
                opts.opt :name,         "Product name",             :short => "-n", :long => "--name",                :type => :string
                opts.opt :prod_version, "Product version",          :short => "-r", :long => "--release_version",     :type => :string
                opts.opt :dep_name,     "Dependency product name",  :short => "-d", :long => "--dependency_name",     :type => :string
                opts.opt :dep_version,  "Dependency version",       :short => "-s", :long => "--dependency_version",  :type => :string
              end
              add_dependency.action do |options, arguments|
                Uhuru::UCC::Publisher::Versions.new(options, arguments).add_dependency
              end
            end
          end

          app.command :upload do |command|
            command.summary "[version]"

            command.command :version do |upload_version|
              upload_version.summary "Upload version"
              upload_version.description "Upload new product version"
              upload_version.options do |opts|
                opts.opt :name,         "Product name",           :short => "-n", :long => "--name",            :type => :string
                opts.opt :prod_version, "Product version",        :short => "-r", :long => "--release_version", :type => :string
                opts.opt :type,         "Version type",           :short => "-t", :long => "--type",            :type => :string
                opts.opt :description,  "Description",            :short => "-d", :long => "--description",     :type => :string
                opts.opt :file,         "Release file to upload", :short => "-f", :long => "--file",            :type => :string

                opts.validate(:file, "does not exist") {|file| File.exists?(file)}
                opts.validate(:type, "must be one of the following: [alpha, beta, RC, final, nightly]") {|option| ["alpha", "beta", "RC", "final", "nightly"].include?(option) }
              end
              upload_version.action do |options, arguments|
                Uhuru::UCC::Publisher::Versions.new(options, arguments).upload_version
              end
            end
          end

          app.command :website do |command|
            command.summary "Web Interface"

            command.command :start do |start_web_interface|
              start_web_interface.summary "Start web-server"
              start_web_interface.description "Start web-server with web interface"

              start_web_interface.options do |opts|
                opts.opt :port,         "Port for web interface",           :short => "-p",   :long => "--port",            :type => :string
                opts.opt :domain, "Ip or domain for web interface",         :short => "-d",   :long => "--domain",          :type => :string
              end

              start_web_interface.action do |_, _|
                Uhuru::UCC::Publisher::WebInterface.run!
              end
            end
          end


          app.command :delete do |command|
            command.summary "[product, version]"
            command.command :product do |delete_product|
              delete_product.summary "Delete product"
              delete_product.description "Delete an existing product"
              delete_product.options do |opts|
                opts.opt :name,         "Product name",                         :short => "-n", :long => "--name",        :type => :string
                opts.opt :cascade,      "Cascade delete",                       :short => "-c", :long => "--cascade",     :type => :boolean
              end
              delete_product.action do |options, arguments|
                Uhuru::UCC::Publisher::Products.new(options, arguments).delete_product
              end
            end

            command.command :version do |delete_version|
              delete_version.summary "Delete version"
              delete_version.description "Delete product version"
              delete_version.options do |opts|
                opts.opt :name,         "Product name",           :short => "-n", :long => "--name",            :type => :string
                opts.opt :prod_version, "Product version",        :short => "-r", :long => "--release_version", :type => :string
              end
              delete_version.action do |options, arguments|
                Uhuru::UCC::Publisher::Versions.new(options, arguments).delete_version
              end
            end
          end
        end
      end
    end
  end
end

