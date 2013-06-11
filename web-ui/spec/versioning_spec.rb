require "rspec"
require 'fileutils'
require File.expand_path('../../lib/versioning/product', __FILE__)
require File.expand_path('../../lib/versioning/version', __FILE__)
require File.expand_path('../../lib/runner', __FILE__)
require File.expand_path('../../lib/ucc/stemcell', __FILE__)
require File.expand_path('../../lib/ucc/commander_bosh_runner', __FILE__)
require 'spec_helper'

describe "Product loading from configuration" do

  before(:each) do
    @config_file = File.expand_path("../../config/config_dev.yml", __FILE__)

    Uhuru::BoshCommander::Runner.init_config @config_file
  end

  it "should be empty if there's no products.yml" do
    $config[:versioning_dir] = "/tmp/dummy_dir/"
    products = Uhuru::BoshCommander::Versioning::Product.get_products
    products.should == {}
  end

  it "should populate objects" do
    products = Uhuru::BoshCommander::Versioning::Product.get_products
    products.size.should == 3
  end

  it "should map product names to products" do
    products = Uhuru::BoshCommander::Versioning::Product.get_products
    products['ucc'].should_not == nil
  end

  it "should also load versions" do
    products = Uhuru::BoshCommander::Versioning::Product.get_products
    products['ucc'].versions.should_not == nil
    products['ucc'].versions.size.should == 4
  end

  it "should map versions back to products" do
    products = Uhuru::BoshCommander::Versioning::Product.get_products
    products['ucc'].versions.first.product == products['ucc']
  end

  it "should detect remote only state" do
    products = Uhuru::BoshCommander::Versioning::Product.get_products
    products['ucc'].versions['1.0.7'].get_state.should == Uhuru::BoshCommander::Versioning::Version::STATE_REMOTE_ONLY
  end

  it "should detect downloading state" do
    products = Uhuru::BoshCommander::Versioning::Product.get_products
    products['ucc'].versions['1.0.8'].get_state.should == Uhuru::BoshCommander::Versioning::Version::STATE_DOWNLOADING
  end

  it "should detect local state" do
    products = Uhuru::BoshCommander::Versioning::Product.get_products
    products['ucc'].versions['1.0.9'].get_state.should == Uhuru::BoshCommander::Versioning::Version::STATE_LOCAL
  end

  it "should detect missing dependencies" do
    products = Uhuru::BoshCommander::Versioning::Product.get_products
    products['ucc'].versions['1.0.9'].dependencies_ok?.should == false
  end

  it "should detect installed UCC version" do
    products = Uhuru::BoshCommander::Versioning::Product.get_products
    products['ucc'].versions['1.0.9.f'].get_state.should == Uhuru::BoshCommander::Versioning::Version::STATE_DEPLOYED
  end

  it "should detect available dependencies" do
    products = Uhuru::BoshCommander::Versioning::Product.get_products
    products['uhuru-windows-2008R2'].versions['0.9.9'].dependencies_ok?.should == true
  end

  it "should detect partial missing dependencies" do
    products = Uhuru::BoshCommander::Versioning::Product.get_products
    products['uhuru-windows-2008R2'].versions['0.0.8'].dependencies_ok?.should == false
  end

  it "should detect invalid dependencies" do
    products = Uhuru::BoshCommander::Versioning::Product.get_products
    products['uhuru-windows-2008R2'].versions['0.0.7'].dependencies_ok?.should == false
  end

  it "should check bosh for stemcell version" do
    session = SpecHelper.bosh_login
    products = Uhuru::BoshCommander::Versioning::Product.get_products

    Uhuru::BoshCommander::CommanderBoshRunner.execute(session) do
      products['uhuru-windows-2008R2'].versions['0.9.9'].get_state.should == Uhuru::BoshCommander::Versioning::Version::STATE_AVAILABLE
    end
  end
end