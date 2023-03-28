
require 'erb'

require_relative '../user_info'

module Dockerun
  module Template

    class TemplateWriter
      include UserInfo 

      class TemplateNotFound < StandardError; end

      attr_accessor :image, :user_group_id, :user_group_name, :user_id, :user_login, :maintainer, :image_base
      attr_writer :user_configurables

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
        @image_base = :ubuntu
      end

      def user_configurables
        fields = {
          image: { desc: "Image name of the docker based on", required: true },
          image_base: { desc: "Image is based on which OS? Assumption with be on Debian based. ", default: :ubuntu },
          maintainer: { desc: "Maintainer of the Dockerfile", default: @maintainer }
        }

        if TR::RTUtils.on_linux?
          f2 = {
            user_group_id: { desc: "User group ID that shall be created in docker. Default to current running user's ID", default: @user_group_id.to_s },
            user_group_name: { desc: "User group name that shall be created in docker. Default to current running user's group", default: @user_group_name },
            user_id: { desc: "User ID that shall be created in docker. Default to current running user ID", default: @user_id.to_s },
            user_login: { desc: "User login name that shall be created in docker. Default to current running user's login", default: @user_login }
          }
          fields.merge!(f2)
        end
        fields
      end

      def compile(&block)

        if not_empty?(@user_configurables)
          @user_configurables.each do |k,v|
            begin
              self.send("#{k}=", v)
            rescue Exception => ex
              STDERR.puts "Setting value exception : #{ex}"
            end
          end
        end

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
