require "rspec"
require 'fileutils'
require File.expand_path('../../lib/versioning/product', __FILE__)
require File.expand_path('../../lib/versioning/version', __FILE__)
require File.expand_path('../../lib/runner', __FILE__)

describe "Product loading from configuration" do

  before(:each) do
    Uhuru::BoshCommander::Runner.init_config
  end

  it "should be empty if there's no products.yml" do
    $config[:versioning_dir] = "/dummy_dir/"
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
    products['ucc'].versions.size.should == 3
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
end