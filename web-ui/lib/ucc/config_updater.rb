require 'pathname'

# class used for the update configurations
module Uhuru::BoshCommander
  class ConfigUpdater

    JOBS_DIR = '/var/vcap/jobs'

    # returns all jobs
    def self.get_all_jobs
      job_directories = Dir.glob File.join(JOBS_DIR, '*')

      job_directories.map do |dir|
        Pathname.new(dir).relative_path_from(Pathname.new(JOBS_DIR)).to_s
      end
    end

    # apply the spec for a job
    def self.apply_spec_for_job(job)
      job_dir = File.join(JOBS_DIR, job)
      templates_dir = File.join(job_dir, 'uhuru_templates')
      generate_templates_script = File.join(job_dir, 'uhuru_templates' , 'generate_templates.rb')
      ruby_interpreter = File.join(RbConfig::CONFIG['bindir'], 'ruby')
      output = `#{ruby_interpreter} #{generate_templates_script} #{templates_dir} #{job_dir}`
      $logger.info("Applied spec for job '#{job}' - #{output}")
    end

    # apply spec for all the jobs
    def self.apply_spec_for_all_jobs
      ConfigUpdater.get_all_jobs.each do |job|
        ConfigUpdater.apply_spec_for_job(job)
      end
    end
  end
end