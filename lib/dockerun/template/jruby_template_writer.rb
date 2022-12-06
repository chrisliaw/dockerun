
require_relative 'template_writer'

module Dockerun
  module Template
    class JrubyTemplateWriter < TemplateWriter
     
      def initialize
        super
      end

      alias_method :find_template, :find_template_super
      def find_template
        case @template
        when "jruby-9.4.0-jdk11"
          @image = "jruby:9.4.0-jdk11"
        end

        find_template_super
      end

    end
  end
end
