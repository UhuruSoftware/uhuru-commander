# Class that uses plugin_manager gem to dynamically load plugins
class PluginManager
  # Adds a plugin source with version from the directory source
  # directory = directory path where is the plugin source
  #
  def add_plugin_version_source(directory)
    definition_files = Dir[File.join(File.expand_path(directory), "bits", "plugin.rb")]
    definition_files.reject! {|file| plugins.any? {|pl| pl.definition_file == File.expand_path(file) } }

    add_definition_files(definition_files)
  end

  # Class that contains the plugin definition
  class PluginDefinition

    # Loads the plugin files
    def load
      time = Time.now
      required_files.each {|file| $".delete(file) }
      load_file = File.expand_path(File.join(File.dirname(definition_file), file))
      $:.unshift(File.dirname(load_file))
      new_files = log_requires do
        Kernel.load "#{load_file}.rb"
      end
      required_files.unshift(*new_files)
      if object.respond_to?(:loaded)
        object.loaded
      end
      @load_time = Time.now - time
    end
  end
end