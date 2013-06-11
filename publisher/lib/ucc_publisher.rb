require 'bundler/setup'
require 'rubygems'
require "yaml"

require "escort"
require "terminal-table"
require "blobstore_client"

require "client"
require "products"
require "versions"

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
          end

          app.command :add do |command|
            command.command :product do |add_product|
              add_product.summary "Add product"
              add_product.description "Add a new product"
              add_product.options do |opts|
                opts.opt :name,         "Product name",                         :short => "-n", :long => "--name",        :type => :string
                opts.opt :label,        "Product label",                        :short => "-l", :long => "--label",       :type => :string
                opts.opt :description,  "Product description",                  :short => "-d", :long => "--description", :type => :string
                opts.opt :type,         "Product type [ucc, stemcell]",         :short => "-t", :long => "--type",        :type => :string
                opts.opt :force,        "Force overwrite",                      :short => "-f", :long => "--force",       :type => :boolean, :default => false

                opts.validate(:type, "must be one of the following: [ucc, stemcell]") {|option| ["ucc", "stemcell"].include?(option) }
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
              end
              upload_version.action do |options, arguments|
                Uhuru::UCC::Publisher::Versions.new(options, arguments).upload_version
              end
            end
          end
        end
      end
    end
  end
end

