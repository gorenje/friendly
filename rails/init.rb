config = YAML.load(ERB.new(File.read(RAILS_ROOT + "/config/friendly.yml").result))[RAILS_ENV]
Friendly.configure(config)

