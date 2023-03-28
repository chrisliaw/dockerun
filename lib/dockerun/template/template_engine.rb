

module Dockerun
  module Template
    class TemplateEngine

      def self.template_root
        File.join(File.dirname(__FILE__),"..","..","..","template")
      end

      def self.available_templates
        avail = Dir.glob(File.join(template_root,"Dockerfile_*.erb"))

        #userDir = File.join(Dir.home,".dockerun","template")
        #if File.exist?(userDir)
        #  avail += Dir.glob(userDir,"*.erb")
        #end
        
        avail.map! { |f| 
          name = File.basename(f,File.extname(f))
          name.gsub("Dockerfile_","")
        }
      end

    end
  end
end
