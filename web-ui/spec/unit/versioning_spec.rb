require "rspec"
require 'fileutils'
require File.expand_path("../../spec_helper.rb", __FILE__)

describe 'Blobstore client' do
  before(:each) do
    load_config
  end

  it 'should retrieve products manifest from blobstore' do
    $config[:versioning][:dir] = "/tmp/dummy_dir2/"
    FileUtils.rm_rf $config[:versioning][:dir]
    Uhuru::BoshCommander::Versioning::Product.download_manifests

    File.exist?(File.join($config[:versioning][:dir], 'products.yml')).should == true
  end

  it 'should download version bits locally' do
    Uhuru::BoshCommander::CommanderBoshRunner.execute(session) do
      $config[:versioning][:dir] = "/tmp/dummy_dir2/"
      FileUtils.rm_rf $config[:versioning][:dir]
      Uhuru::BoshCommander::Versioning::Product.download_manifests
      Uhuru::BoshCommander::Versioning::Product.get_products['ucc'].versions['0.0.1'].download_from_blobstore.join

      Uhuru::BoshCommander::Versioning::Product.get_products['ucc'].versions['0.0.1'].get_state.should == Uhuru::BoshCommander::Versioning::STATE_LOCAL
    end

  end
end

describe 'Bits Management' do
  it 'should delete local bits for a version properly, if there are no deployments' do
    Uhuru::BoshCommander::CommanderBoshRunner.execute(session) do

      $config[:versioning][:dir] = "/tmp/dummy_dir2/"
      FileUtils.rm_rf $config[:versioning][:dir]
      Uhuru::BoshCommander::Versioning::Product.download_manifests
      Uhuru::BoshCommander::Versioning::Product.get_products['ucc'].versions['0.0.1'].download_from_blobstore.join
      Uhuru::BoshCommander::Versioning::Product.get_products['ucc'].versions['0.0.1'].delete_bits

      Uhuru::BoshCommander::Versioning::Product.get_products['ucc'].versions['0.0.1'].get_state.should == Uhuru::BoshCommander::Versioning::STATE_REMOTE_ONLY
    end

  end

  it 'should not allow deletion of local bits for a version that is in use' do
    $config[:versioning][:dir] = "/tmp/dummy_dir2/"
    FileUtils.rm_rf $config[:versioning][:dir]
    Uhuru::BoshCommander::Versioning::Product.download_manifests

    expect { Uhuru::BoshCommander::Versioning::Product.get_products['ucc'].versions['0.0.1'].delete_bits }.to raise_error
  end
end

describe "Product loading from configuration" do

  before(:each) do
    @config_file = File.expand_path("../../../config/config_dev.yml", __FILE__)
    Uhuru::BoshCommander::Runner.init_config @config_file
    $config[:versioning][:dir] = File.expand_path("../../assets/versioning_spec_dir/", __FILE__)
  end

  it "should be empty if there's no products.yml" do
    $config[:versioning][:dir] = "/tmp/dummy_dir/"
    FileUtils.rm_rf $config[:versioning][:dir]
    products = Uhuru::BoshCommander::Versioning::Product.get_products
    products.should == {}
  end

  it "should populate objects" do
    products = Uhuru::BoshCommander::Versioning::Product.get_products
    products.size.should == 4
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
    products['ucc'].versions['1.0.7'].get_state.should == Uhuru::BoshCommander::Versioning::STATE_REMOTE_ONLY
  end

  it "should detect downloading state" do
    products = Uhuru::BoshCommander::Versioning::Product.get_products
    products['ucc'].versions['1.0.8'].get_state.should == Uhuru::BoshCommander::Versioning::STATE_DOWNLOADING
  end

  it "should detect local state" do
    products = Uhuru::BoshCommander::Versioning::Product.get_products
    products['ucc'].versions['1.0.9'].get_state.should == Uhuru::BoshCommander::Versioning::STATE_LOCAL
  end

  it "should detect missing dependencies" do
    products = Uhuru::BoshCommander::Versioning::Product.get_products
    products['ucc'].versions['1.0.9'].dependencies_ok?.should == false
  end

  it "should detect installed UCC version" do
    products = Uhuru::BoshCommander::Versioning::Product.get_products
    products['ucc'].versions['1.0.9.f'].get_state.should == Uhuru::BoshCommander::Versioning::STATE_DEPLOYED
  end

  it "should detect available dependencies" do
    products = Uhuru::BoshCommander::Versioning::Product.get_products
    products['uhuru-windows-2008R2'].versions['0.9.9'].dependencies_ok?.should == true
  end

  it "should detect partial missing dependencies" do
    Uhuru::BoshCommander::CommanderBoshRunner.execute(session) do
      products = Uhuru::BoshCommander::Versioning::Product.get_products
      products['uhuru-windows-2008R2'].versions['0.0.8'].dependencies_ok?.should == false
    end

  end

  it "should detect invalid dependencies" do
    products = Uhuru::BoshCommander::Versioning::Product.get_products
    products['uhuru-windows-2008R2'].versions['0.0.7'].dependencies_ok?.should == false
  end

  it "should check bosh for stemcell version" do

    Uhuru::BoshCommander::CommanderBoshRunner.execute(session) do
      products = Uhuru::BoshCommander::Versioning::Product.get_products
      products['uhuru-windows-2008R2'].versions['0.9.9'].get_state.should satisfy { |s|
        [Uhuru::BoshCommander::Versioning::STATE_AVAILABLE, Uhuru::BoshCommander::Versioning::STATE_DEPLOYED].include?(s)
      }
    end
  end
end