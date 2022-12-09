
require 'tty/prompt'
require 'docker/cli'

require_relative '../config'
require_relative '../docker_container_helper'

require_relative '../docker_command_factory_helper'
require_relative '../cli_prompt'

module Dockerun
  module Command
    class RunNewContainer
      include TTY::Option
      include TR::CondUtils
      include CommandHelper::DockerContainerHelper

      include DockerCommandFactoryHelper
      include CliHelper::CliPrompt


      usage do
        program "dockerun"
        command "run-new-container"
        desc "Run new container from same image"
      end

      def run

        if params[:help]
          print help
          exit(0)

        else

          config = ::Dockerun::Config.from_storage

          imageName = nil
          if is_empty?(config.image_names)
            STDERR.puts "Image name not availab eyet"
            exit(1)
          elsif config.image_names == 1
            imageName = config.image_names.first
          else
            imageName = cli.select("Please select the new container shall be based on which image : ") do |m|
              config.image_names.each do |n|
                m.choice n,n
              end
            end
          end

          contName = run_docker_container(imageName, nil) do |ops, *args|
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

          #contName = nil
          #loop do
          #  contName = cli.ask("Please provide a new container name : ", required: true)
          #  res = dcFact.find_from_all_container(contName).run
          #  if not res[:result].failed? and not_empty?(res[:outStream])
          #    STDERR.puts "Given container name '#{contName}' already taken. Please try again"
          #  else
          #    break
          #  end
          #end

          #create_new_docker_container(config, contName, dcFact. cli)
          config.add_container(imageName, contName)
          config.to_storage

        end
        
      end

    end
  end
end
