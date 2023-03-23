
require_relative '../cli_prompt'
require_relative '../config'
require_relative '../docker_container_helper'

module Dockerun
  module Command
    
    class StopContainer

      include TTY::Option
      include TR::CondUtils
      include CommandHelper::DockerContainerHelper
      include DockerCommandFactoryHelper
      include CliHelper::CliPrompt

      usage do
        program "dockerun"
        command "stop"
        desc "Stop a running container"
      end

      def run(&block)
        if params[:help]
          print help
          exit(0)

        else

          # find history file
          config = ::Dockerun::Config.from_storage

          res = []
          opts = []
          config.image_names.each do |im|
            config.container_names(im).each do |cn|
              if is_container_exist?(cn)
                if is_container_running?(cn)
res << "#{im} : #{cn} (Running)"
                  opts << cn
                else
                  res << "#{im} : #{cn} (Not Running)"
                end
              else
                res << "#{im} : #{cn} (Not Exist)"
              end
            end
          end 

          if not opts.empty?
            cli.puts "\n Running status of container(s) : ".yellow
            res.sort.each do |r|
              cli.puts " * #{r}".yellow
            end

            cli.puts
            selConts = cli.multi_select("Please select which container to stop : ") do |m|
              opts.each do |o|
                m.choice o,o
              end

              m.choice "Abort", :quit
            end

            if selConts.include?(:quit)
              cli.puts " * Abort was one of the selected option. Command aborted.".red
            else
              selConts.each do |sc|
                begin
                  stop_container(sc)
                  cli.puts " Container '#{sc}' stopped successfully.".green
                rescue DockerContainerStopFailed => ex
                  cli.puts " Container '#{sc}' failed to be stopped".red
                end
              end
            end

          else
            cli.say " * There is no container found to be running * ".yellow
          end

          cli.puts "\n Stop container command completed successfully \n\n".yellow

        end
      end

    end

  end
end
