
require 'tty/option'

require_relative '../template/template_writter'

module Dockerun
  module Command
    
    class Init
      include TTY::Option
      include TR::CondUtils

      class MultipleTemplateDetected < StandardError; end
      
      usage do
        program "dockerun"
        command "init"
        desc "Initialize a Dockerfile template in given location"
      end

      argument :location do
        required
        desc "Location where the Dockerfile template shall be written"
      end

      def run(&block)
        if params[:help]
          print help
          exit

        else
          init_dockerfile(&block)
        end
      end

      def init_dockerfile(&block)

        loc = "."
        loc = params[:location] if not_empty?(params[:location])

        loc = File.expand_path(loc)
        out = nil
        if File.directory?(loc)
          out = File.join(loc, "Dockerfile.dockerun")
        else
          out = File.join(File.dirname(loc), "Dockerfile.dockerun")
        end

        avail = ::Dockerun::Template::TemplateEngine.available_templates
        selTemp = nil
        if avail.length > 1
          if block
            selTemp = block.call(:multiple_templates_detected, avail)
          else
            raise MultipleTemplateDetected, "Multiple template is available but no selected is given."
          end
        else
          selTemp = avail.first
        end

        tw = ::Dockerun::Template::TemplateWriter.new(selTemp)
        res = tw.compile

        File.open(out, "w") do |f|
          f.write res
        end

        out

      end

    end # class Init

  end # module Command
end # module Dockerun
