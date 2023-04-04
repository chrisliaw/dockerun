
require_relative '../config'
require_relative '../docker_container_helper'

require_relative '../cli_prompt'
require_relative '../docker_command_factory_helper'

require_relative '../docker_image_helper'

module Dockerun
  module Command
    
    class Run
      include TTY::Option
      include TR::CondUtils
      include CommandHelper::DockerContainerHelper
      include DockerCommandFactoryHelper
      include CommandHelper::DockerImageHelper

      usage do
        program "dockerun"
        command "run"
        desc "Run docker instance from here"
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

          imageName = nil

          if config.image_names.length == 0
            imageName = nil 
          elsif config.image_names.length == 1
            imageName = config.image_names.first
          else
            selImg = cli.select("Please select one of the Docker image options below : ") do |m|
              config.image_names.each do |n|
                m.choice n, n
              end

              m.choice "New image", :new
            end

            case selImg
            when :new
              imageName = cli.ask("Please provide a new image name : ", required: true)
            else
              imageName = selImg
            end
          end


          imageName, mount_points = build_image_if_not_exist(imageName) do |ops, *val|
            case ops
            when :new_image_name
              cli.ask("Please provide a new image name : ".yellow, required: true)

            when :image_exist
              reuse = cli.yes? "Image '#{val.first}' already exist. Using existing image?"
              # proceed or not , new name
              [reuse, val.first]

            when :prompt_mount_points_starting
              cli.say "\n Mount Directory into Docker : \n", color: :yellow

            when :transfer_dev_gem_mapping?
              found = val.first
              cli.say(" It seems that the project has development gem attached to it : \n Found development gems (#{found.length}) : \n", color: :yellow)
              if not found.nil? 
                found.each do |name, path|
                  cli.say("  * #{name} [#{path}]\n", color: :yellow)
                end
              end
              cli.yes?(" Do you want to map the above development gems inside the docker? : ".yellow)

            when :workspace_root_inside_docker
              cli.ask("\n Workspace '#{val[2]}' shall be mapped to which directory inside the docker? : ".yellow, required: true, value: File.join(val.first, val[1]))

            when :map_project_dir
              res = cli.ask("\n Please provide path inside docker for current directory [Empty to skip mounting current directory] : ".yellow, value: File.join(val.first, File.basename(Dir.getwd)) )
              if is_empty?(res)
                cli.puts "\n Current directory '#{Dir.getwd}' shall not be available inside the docker".red
              end
              res

            when :volume_mapping_required?
              cli.yes?("\n Is there any other volume mapping required? ".yellow)

            when :source_prompt
              param = val.first
              msg = []
              if not param.nil?
                msg = param[:control] 
              end
              cli.ask("\n Directory to share with docker [#{msg.join(", ")}] : ".yellow, required: true)

            when :destination_prompt
              src = val.first
              srcDir = File.basename(src)
              cli.ask("\n Directory inside docker : ".yellow, required: true, value: "/opt/#{srcDir}")

            when :add_to_bundle?
              cli.yes?("\n Add directory '#{val.first}' to bundler config local? ".yellow)

            when :add_mount_to_container
              config.add_mount_to_container(imageName, *val)

            when :add_more_volume_mapping?
              cli.yes?("\n Add more volume mapping? ".yellow)

            when :prompt_user_configurables
              vv = val.first
              cli.say "\n The following are the configurable items for the template '#{vv[:template]}' : \n".yellow
              res = {  }
              vv[:userFields].each do |k,v|
                case v[:type]
                when :ask
                  res[k] = cli.ask(v[:desc].yellow) do |s|
                    s.required v[:required]  if not_empty?(v[:required]) and is_bool?(v[:required])
                    s.value v[:default].to_s if not_empty?(v[:default])
                  end

                when :select
                  res[k] = cli.select(v[:desc].yellow) do |m|
                    v[:options].each do |opt, key|
                      m.choice opt, key
                    end
                    #m.default v[:default] if not_empty?(v[:default])
                  end
                end
              end

              res

            else

            end
          end

          config.add_image(imageName)

          contNames = config.container_names(imageName)

          selContName = nil
          if contNames.length == 0
            selContName = nil
          elsif contNames.length == 1
            selContName = contNames.first
          else
            sel = cli.select("Please select one of the container operations below : ") do |m|
              contNames.each do |n|
                m.choice n,n
              end

              m.choice "New Container", :new
            end

            case sel
            when :new

            else
              selContName = sel
            end
          end

          selContName = run_docker_container(imageName, selContName, mount_points) do |ops, *args|
            case ops
            when :new_container_name
              cli.ask("\n Please provide a new container name : ".yellow, required: true)
            when :container_name_exist
              cli.yes?(" ** Container name '#{args.first}' already exist. Proceed with existing?".red)

            #when :transfer_dev_gem_mapping?
            #  cli.yes?("It seems that the project has development gem attached to it. Do you want to map those development gems too inside the docker? ")

            #when :workspace_root_inside_docker
            #  cli.ask(" Workspace '#{args[2]}' shall be mapped to which directory inside the docker? ", required: true, value: File.join(args.first, args[1]))

            #when :map_project_dir
            #  cli.ask(" Please provide path inside docker for current directory [Empty to skip mounting current directory] : ", value: File.join(args.first, File.basename(Dir.getwd)), required: true)

            #when :volume_mapping_required?
            #  cli.yes?("Is there any volume mapping required? ")
            #when :source_prompt
            #  cli.ask("Directory to share with docker : ", required: true)
            #when :destination_prompt
            #  src = args.first
            #  srcDir = File.basename(src)
            #  cli.ask("Directory to show inside docker : ", required: true, value: "/opt/#{srcDir}")

            #when :add_to_bundle?
            #  cli.yes?(" Add directory '#{args.first}' to bundler config local? ")

            #when :add_mount_to_container
            #  config.add_mount_to_container(imageName, *args)
            #when :add_more_volume_mapping?
            #  cli.yes?("Add more volume mapping?")
            end
          end

          config.add_container(imageName, selContName)

          config.to_storage

        end 
      end

    end

  end
end
