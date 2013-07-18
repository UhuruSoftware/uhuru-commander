require "rspec"
require 'fileutils'
require 'spec_helper'

describe 'Version number comparison' do

  before(:each) do
    @config_file = File.expand_path("../../../config/config_dev.yml", __FILE__)
    Uhuru::BoshCommander::Runner.init_config @config_file
    $config[:versioning][:dir] = File.expand_path("../../assets/comparison_products_and_versions", __FILE__)
  end

  it "< should not fail" do
    products = Uhuru::BoshCommander::Versioning::Product.get_products

    (products['bosh-stemcell-php-vsphere'].versions['1.5.0.pre.3'] < products['bosh-stemcell-php-vsphere'].versions['1.5.0.pre.4']).should == true

  end

  it "> should not fail" do
    products = Uhuru::BoshCommander::Versioning::Product.get_products

    (products['bosh-stemcell-php-vsphere'].versions['1.5.0.pre.3'] > products['bosh-stemcell-php-vsphere'].versions['1.5.0.pre.4']).should == false
  end

  it "== should not fail" do
    products = Uhuru::BoshCommander::Versioning::Product.get_products

    (products['bosh-stemcell-php-vsphere'].versions['1.5.0.pre.3'] == products['bosh-stemcell-php-vsphere'].versions['1.5.0.pre.4']).should == false
  end

  it "should be able to compare anything" do
    Uhuru::BoshCommander::Versioning::Product.get_products.each do |_, product|
      product.versions.values.each do |version_a|
        product.versions.values.each do |version_b|
          expect {
            version_a > version_b
            version_a < version_b
            version_a == version_b
          }.to_not raise_error
        end
      end
    end
  end

  it "should be able to sort" do
    Uhuru::BoshCommander::Versioning::Product.get_products.each do |_, product|
      product.versions.values.sort.size.should_not == 0
    end
  end
end