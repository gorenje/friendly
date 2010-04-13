configuration_path = RAILS_ROOT + "/config/friendly.yml"
if File.exists?(configuration_path)
  config = YAML.load(ERB.new(File.read(configuration_path).result))[RAILS_ENV]
  Friendly.configure(config)
end

