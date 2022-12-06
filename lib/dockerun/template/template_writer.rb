
require 'erb'

require_relative '../user_info'

module Dockerun
  module Template

    class TemplateWriter
      include UserInfo 

      class TemplateNotFound < StandardError; end

      attr_accessor :image, :user_group_id, :user_group_name, :user_id, :user_login

      def self.instance(template)
        tmp = template.to_s.downcase
        if tmp =~ /jruby/
          JrubyTemplateWriter.new
        else
          TemplateWriter.new
        end
      end
      
      def initialize(template = :general)
        @template = template
        @image = "<Replace me>"
        user = user_info
        group = group_info
        @maintainer = user[:login]
        @user_group_id = group[:group_id]
        @user_group_name = group[:group_name]
        @user_id = user[:user_id]
        @user_login = user[:login]
      end

      def compile(&block)
        tmp = find_template
        cont = nil
        File.open(tmp,"r") do |f|
          cont = f.read
        end

        b = binding

        res = ERB.new(cont)
        res.result(b)
      end

      protected
      def find_template
        @template = :general if is_empty?(@template)

        root = TemplateEngine.template_root
        templateFile = File.join(root,"Dockerfile_#{@template}.erb")
        raise TemplateNotFound, "Given template '#{@template}' could not be found" if not File.exist?(templateFile)

        templateFile
      end

    end
  end
end
