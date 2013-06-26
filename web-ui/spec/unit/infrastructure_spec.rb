require 'spec_helper'

describe 'Setup Infrastructure' do
  before(:each) do
    @config_file = File.expand_path("../../../config/config_dev.yml", __FILE__)
    Uhuru::BoshCommander::Runner.init_config @config_file

    random_string =  (0...10).map{ ('a'..'z').to_a[rand(26)] }.join
    @properties_dev_file = File.join('/tmp/', random_string)
    FileUtils.cp(File.expand_path("../../../config/properties_dev.yml",__FILE__), @properties_dev_file)
    $config[:properties_file] = @properties_dev_file
    @infrastructure_dev_file = File.expand_path("../../../config/infrastructure_dev.yml", __FILE__)
  end

  after(:each) do
     puts @properties_dev_file
     #File.delete(@properties_dev_file)
  end

  it 'should correctly configure properties' do
    director_yml = load_yaml_file(@infrastructure_dev_file)
    infrastructure = Uhuru::BoshCommander::BoshInfrastructure.new
    infrastructure.setup_micro(@infrastructure_dev_file)

  end

end