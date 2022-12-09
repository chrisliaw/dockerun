
require_relative '../config'
require_relative '../docker_container_helper'

require_relative '../cli_prompt'
require_relative '../docker_command_factory_helper'

require_relative '../docker_image_helper'

module Dockerun
  module Command
    
    class RunNewImage
      include TTY::Option
      include TR::CondUtils
      include CommandHelper::DockerContainerHelper
      include DockerCommandFactoryHelper
      include CommandHelper::DockerImageHelper

      usage do
        program "dockerun"
        command "run-new-image"
        desc "Run with new image"
      end

      argument :command_for_docker do
        optional
        desc "Command to be passed to docker"
      end

      def run(&block)
        if params[:help]
          print help
          exit(0)

        else

          # find history file
          config = ::Dockerun::Config.from_storage

          imageName = build_image_if_not_exist(imageName) do |ops, val|
            case ops
            when :new_image_name
              cli.ask("Please provide a new image name : ", required: true)
            when :image_exist
              reuse = cli.yes? "Image '#{val}' already exist. Using existing image?"
              # proceed or not , new name
              [reuse, val]
            else

            end
          end

          config.add_image(imageName)

          contNames = config.container_names(imageName)

          selContName = run_docker_container(imageName, selContName) do |ops, *args|
            case ops
            when :new_container_name
              cli.ask("Please provide a new container name : ", required: true)
            when :container_name_exist
              cli.yes?("Container name '#{args.first}' already exist. Proceed with existing?")
            when :volume_mapping_required?
              cli.yes?("Is there any volume mapping required? ")
            when :source_prompt
              cli.ask("Directory to share with docker : ", required: true)
            when :destination_prompt
              cli.ask("Directory to show inside docker : ", required: true)
            when :add_mount_to_container
              config.add_mount_to_container(imageName, *args)
            when :add_more_volume_mapping?
              cli.yes?("Add more volume mapping?")
            end
          end

          config.add_container(imageName, selContName)

          config.to_storage

        end 
      end

    end

  end
end
