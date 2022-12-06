
require 'tty/prompt'
require 'docker/cli'

require_relative '../config'
require_relative '../docker_command_factory_helper'
require_relative '../cli_prompt'


module Dockerun
  module Command
    class RemoveContainer
      include TTY::Option
      include TR::CondUtils

      include DockerCommandFactoryHelper
      include CliHelper::CliPrompt

      usage do
        program "dockerun"
        command "rmc"
        desc "Remove container"
      end

      def run
        if params[:help]
          print help
          exit(0)

        else

          config = ::Dockerun::Config.from_storage

          imageName = nil
          if is_empty?(config.image_names)
            raise Error, "No image found"
          elsif config.image_names.length == 1
            imageName = config.image_names.first
          else
            imageName = cli.select("Please select one of the image below to start : ") do |m|
              config.image_names.each do |n|
                m.choice n,n
              end
            end
          end

          if is_empty?(config.container_names(imageName))
            STDOUT.puts "There is no container registered under image '#{imageName}'"
          else

            loop do

              sel = cli.select("Please select the container that would like to be removed : ") do |m|
                config.container_names(imageName).each do |n|
                  m.choice n,n
                end

                m.choice "Quit", :quit
              end

              case sel
              when :quit
                break
              else
                dcFact.stop_container(sel)
                dcFact.delete_container(sel)
                config.remove_container(imageName, sel)
                config.to_storage

                break if is_empty?(config.container_names(imageName))
              end

            end
          end
          


        end
        
      end

    end
  end
end
