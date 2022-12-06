
require 'tty/option'

module Dockerun
  module Command
    
    class Dockerun
      include TTY::Option

      usage do
        program "dockerun"
        no_command
      end

      argument :command do
        required
        desc "Command for the dockerun operations. Supported: init, run, run-new-container, run-new-image, reset-image, rmc"
      end

      def run
        if params[:help]
          print help
          exit
        end
      end

    end

  end
end
