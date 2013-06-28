module Uhuru::BoshCommander
  class ProductsChecker

    def self.start_checking
      Thread.new do
        1.upto(Float::INFINITY) do
          check_for_updates

          # TODO: this variable needs to be configurable
          sleep(1)
        end
      end
    end

    def self.check_for_updates
      # TODO: was not yet properly tested
      #return Uhuru::BoshCommander::Versioning::Product.download_manifests
    end

  end
end

