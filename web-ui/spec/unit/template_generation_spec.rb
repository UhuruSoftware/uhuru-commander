require "rspec"
require 'fileutils'
require 'spec_helper'
require 'tmpdir'
require File.expand_path('../../../../deb_builder/lib/jobs/job.rb', __FILE__)

$config = YAML.load_file(File.expand_path('../../../../deb_builder/config/config.yml', __FILE__))

describe 'Deb package template generation' do

  bosh_dir = File.expand_path('../../../../modules/private-bosh/', __FILE__)
  ucc_dir = File.expand_path('../../../../', __FILE__)

  Dir[File.join(bosh_dir, 'release/jobs/*')].each do |job|
    job = File.basename(job)

    if Uhuru::BOSH::Converter::Job.is_job_needed_for_cpi(job)

      it "#{job} should work" do

        work_dir = Dir.mktmpdir

        Dir.mkdir File.join(work_dir, 'templates')
        Dir.mkdir File.join(work_dir, 'result')

        `mv -f /var/vcap/store/ucc/web-ui/config/properties.yml /var/vcap/store/ucc/web-ui/config/properties.yml.bkp`


        FileUtils.cp_r Dir[File.join(bosh_dir, "release/jobs/#{job}/templates/*")].collect{|f| File.expand_path(f)}, File.join(work_dir, 'templates')

        FileUtils.cp_r File.join(bosh_dir, 'bosh_common/lib/common/properties'), work_dir
        FileUtils.cp_r File.join(bosh_dir, 'bosh_common/lib/common/properties'), work_dir
        FileUtils.cp_r File.join(bosh_dir, "release/jobs/#{job}/spec"), work_dir
        FileUtils.cp_r File.join(bosh_dir, "release/jobs/#{job}/monit"), work_dir

        FileUtils.cp_r File.join(ucc_dir, 'web-ui/config/properties.yml.erb'), work_dir
        FileUtils.cp_r File.join(ucc_dir, 'deb_builder/lib/jobs/generate_templates.rb'), work_dir


        results = `cd #{work_dir} ; ruby generate_templates.rb . ./result`

        $?.to_i.should eq(0), results

        `mv -f /var/vcap/store/ucc/web-ui/config/properties.yml.bkp /var/vcap/store/ucc/web-ui/config/properties.yml`
      end
    end
  end
end