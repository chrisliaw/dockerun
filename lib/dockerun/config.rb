
require 'yaml'

module Dockerun
  class Config
    include TR::CondUtils

    FILENAME = ".dockerun".freeze

    def self.from_storage
      path = File.join(Dir.getwd, FILENAME)
      if File.exist?(path)
        cont = nil
        File.open(path,"r") do |f|
          cont = f.read
        end

        Config.new(YAML.load(cont), true)
      else
        Config.new({}, false)
      end
    end

    def self.remove
      path = File.join(Dir.getwd, FILENAME)
      FileUtils.rm(path) if File.exist?(path)
    end

    def initialize(configHash = {  }, configFileAvail = false)
      @config = configHash 
      @images = @config[:images]
      @confFileAvail = configFileAvail
      @images = {  } if @images.nil?
    end

    def isConfigFileAvail?
      @confFileAvail
    end

    def image_names
      @images.keys
    end

    def add_image(name)
      @images[name] = {  } if not_empty?(name) and not @images.keys.include?(name)
    end

    def remove_image(name)
      @images.delete(name)
    end

    def container_names(imageName)
      @images[imageName].keys
    end

    def container_configs(imageName, name)
      @images[imageName].nil? ? {} : @images[imageName][name].nil? ? {} : @images[imageName][name]
    end

    def add_container(imageName, name)
      @images[imageName] = {  } if @images[imageName].nil?
      @images[imageName][name] = {} if @images[imageName][name].nil?
    end

    def remove_container(imageName, name)
      if not @images[imageName].nil?
        @images[imageName].delete(name) 
      end
    end

    def add_mount_to_container(imageName, container, mount)
      add_container(imageName, container)
      @images[imageName][container][:mount] = [] if @images[imageName][container][:mount].nil?
      @images[imageName][container][:mount] << mount
    end

    def mount_of_container(container)
      res = @containers[container]
      if is_empty?(res) or is_empty?(res[:mount])
        []
      else
        res[:mount]
      end
    end

    def to_storage
      res = { images: @images } 

      path = File.join(Dir.getwd, FILENAME)
      File.open(path,"w") do |f|
        f.write YAML.dump(res)
      end
    end

  end
end
