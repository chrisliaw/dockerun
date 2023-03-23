
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
        desc "Command for the dockerun operations. Supported: init, run (r), stop (s), run-new-container (rnc), run-new-image (rni), remove-image (rmi), remove-container (rmc)"
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
