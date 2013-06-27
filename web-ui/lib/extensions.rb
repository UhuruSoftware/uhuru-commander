class PluginManager
  def add_plugin_version_source(directory)
    definition_files = Dir[File.join(File.expand_path(directory), "bits", "plugin.rb")]
    definition_files.reject! {|f| plugins.any? {|pl| pl.definition_file == File.expand_path(f) } }

    add_definition_files(definition_files)
  end
end