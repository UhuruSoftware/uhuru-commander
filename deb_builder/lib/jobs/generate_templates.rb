require 'fileutils'
require 'yaml'
require 'erb'
require 'pp'
require 'json'
require 'erb'
require 'securerandom'

source_dir = ARGV[0]
destination = ARGV[1]

module HashRecursiveMerge
  def rmerge(other_hash)
    r = {}
    merge(other_hash) do |key, oldval, newval|
      r[key] = oldval.class == self.class ? oldval.rmerge(newval) : newval
    end
  end
end


class Hash
  include HashRecursiveMerge
end

module Bosh

end

require 'ostruct'

puts 'Loading configuration scripts...'

require File.join(source_dir, 'properties/errors.rb')
require File.join(source_dir, 'properties/property_helper.rb')
require File.join(source_dir, 'properties/template_evaluation_context.rb')

puts "Creating destination directory (#{destination})..."
FileUtils.mkdir_p(destination)

spec_file = File.join(source_dir, 'spec')

puts "Loading spec file (#{spec_file})..."
spec = YAML.load_file(spec_file)


erb_file = File.join(source_dir, 'properties.yml.erb')
template = ERB.new File.new(erb_file).read
defaults = YAML.load(template.result(binding))

existing_properties_file = '/var/vcap/store/ucc/web-ui/config/properties.yml'
if File.exist?(existing_properties_file)
  existing_properties = YAML.load_file(existing_properties_file)
  if existing_properties.is_a?(Hash)
    defaults = defaults.rmerge(existing_properties)
  end
else
  FileUtils.mkdir_p '/var/vcap/store/ucc/web-ui/config/'
end

File.open(existing_properties_file, "w") do |f|
  f.write(defaults.to_yaml)
end

properties = {}
properties['job'] = { 'name' => spec['name'] }
properties['index'] = 0
properties['properties'] = defaults['properties']



if ENV
  ENV.each do |p_name, p_value|
    if p_name.start_with?('uhuruconfig.')

      before_last = nil
      final_particle = nil
      last = properties['properties']
      default_value = defaults['properties']
      p_name.split('.').each do |particle|
        last[particle] ||= {}
        before_last = last
        last = last[particle]
        final_particle = particle
        if default_value
          default_value = default_value[particle]
        end
      end

      before_last[final_particle] = ENV["uhuru.#{p_name}"]
    end
  end
end

puts 'Using the following properties:'
pp properties['properties']

spec['templates'].each do |template_source, template_destination|
  puts "Processing template file (#{template_destination})..."

  template_file = File.join(source_dir, 'templates', template_source)
  template_contents = ERB.new File.new(template_file).read

  template_destination_file = File.join(destination, template_destination)
  FileUtils.mkdir_p(File.expand_path('..', template_destination_file))

  spec_binding = Bosh::Common::TemplateEvaluationContext.new(properties).get_binding

  File.open(template_destination_file, 'w') do |file|
    file.write(template_contents.result(spec_binding))
  end

  `chmod +x #{template_destination_file}`
end

puts 'Processing monit file...'
template_file = File.join(source_dir, 'monit')
template_contents = ERB.new File.new(template_file).read
template_destination_file = template_file
spec_binding = Bosh::Common::TemplateEvaluationContext.new(properties).get_binding
File.open(template_destination_file, 'w') do |file|
  file.write(template_contents.result(spec_binding))
end

