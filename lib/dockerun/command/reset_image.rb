

require 'tty/prompt'

require 'docker/cli'

require_relative '../config'

require_relative '../docker_command_factory_helper'
require_relative '../cli_prompt'

module Dockerun
  module Command
    class ResetImage
      include TTY::Option
      include TR::CondUtils 

      include DockerCommandFactoryHelper
      include CliHelper::CliPrompt

      usage do
        program "dockerun"
        command "reset-image"
        desc "Delete images (and its containers) and start again"
      end

      def run(&block)

        if params[:help]
          print help
          exit(0)

        else

          config = ::Dockerun::Config.from_storage

          if config.isConfigFileAvail?

            skip = cli.no?("Reset docker image (together with the relative container) ? ")
            if not skip

              selImg = nil
              if is_empty?(config.image_names)
                STDOUT.puts "No image found"
                
              elsif config.image_names.length == 1
                selImg = config.image_names.first
              else

                selImg = cli.select("Please select which image you want to reset : ") do |m|
                  config.image_names.each do |n|
                    m.choice n,n
                  end
                end

              end

              if not selImg.nil?

                # start from container first
                config.container_names(selImg).each do |cn|
                  dcFact.stop_container(cn).run
                  dcFact.delete_container(cn).run
                end

                STDOUT.puts "#{config.container_names(selImg).length} container(s) from image '#{selImg}' deleted"

                res = dcFact.delete_image(selImg).run
                if not res.failed?
                  STDOUT.puts "Image '#{selImg}' successfully deleted."
                else
                  STDERR.puts "Image '#{selImg}' deletion failed. Error was : #{res.err_stream}"
                end

                config.remove_image(selImg)

                config.to_storage

              end

              if is_empty?(config.image_names)
                ::Dockerun::Config.remove 
                STDOUT.puts "Dockerun workspace config removed"
              end

            else
              STDOUT.puts "Reset docker image operation aborted"
            end

          else
            STDOUT.puts "Not a dockerun workspace"
          end
        end
        
      end

    end
  end
end
