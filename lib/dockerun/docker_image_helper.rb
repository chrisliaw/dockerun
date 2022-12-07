
require_relative 'cli_prompt'
require_relative 'docker_command_factory_helper'

module Dockerun
  module CommandHelper
    module DockerImageHelper
      include CliHelper::CliPrompt
      include DockerCommandFactoryHelper

      class DockerfileNotExist < StandardError; end
      class DockerImageBuildFailed < StandardError; end
      class DockerImageDeleteFailed < StandardError; end

      def load_dockerfile(root = Dir.getwd)

        df = Dir.glob(File.join(root,"Dockerfile*"))
        if df.length == 0
          raise DockerfileNotExist, "Dockerfile not yet available. Please create one or run init first."
        end

        selectedDf = nil
        if df.length > 1
          selectedDf = cli.select("Please select one of the Dockerfile to proceed: ") do |m|
            df.each do |d|
              m.choice File.basename(d), d
            end
          end
        else
          selectedDf = df.first
        end

        selectedDf
          
      end

      def build_image_if_not_exist(name, &block)
       
        raise DockerImageBuildFailed, "block is required" if not block

        if is_empty?(name)
          reuse = false
          loop do
            name = block.call(:new_image_name)
            break if not is_image_existed?(name)
            reuse, name = block.call(:image_exist, name)
            break if reuse
          end

          if reuse
            
          else
            dockerfile = load_dockerfile(Dir.getwd)
            build_docker_image(name, dockerfile: dockerfile)
          end

        else

            if not is_image_existed?(name)
              dockerfile = load_dockerfile(Dir.getwd)
              build_docker_image(name, dockerfile: dockerfile)
            end

        end

        name

      end

      #def new_image(config, selectedDf)

      #  if not_empty?(selectedDf)
      #    imageName = cli.ask("Please provide an image name : ", required: true)
      #    res = dcFact.find_image(imageName).run
      #    if not res[:result].failed? and not_empty?(res[:outStream])
      #      reuse = cli.yes?("Image named '#{imageName}' already exist. Use the existing image? ")
      #      if reuse
      #        config.image_name = imageName
      #      else
      #        keep = cli.no?("Remove existing image and create a new image? ")
      #        if not keep
      #          res = dcFact.delete_image(imageName).run
      #          if not res[:result].failed?
      #            puts "Existing image with name '#{imageName}' removed."
      #            res = dcFact.build_image(imageName, dockerfile: selectedDf).run
      #            if not res[:result].failed?
      #              config.image_name = imageName
      #            else
      #              raise DockerImageBuildFailed, "Error while building image '#{imageName}'. Error stream : #{res[:errStream].join(" ")}"
      #            end

      #          else
      #            raise DockerImageDeleteFailed, "Error while deleting image '#{imageName}'. Error stream : #{res[:errStream].join(" ")}"
      #          end

      #        else
      #          # user select not to use existing and keep the existing image... 
      #          # nothing can be done then right?
      #          raise Dockerun::Error, "Alreay has existing image with name '#{imageName}' but not reusing the image. System cannot proceed. Please either delete or reuse the image"
      #        end
      #      end # if reuse or not

      #    else

      #      # no existing image
      #      res = dcFact.build_image(imageName, dockerfile: selectedDf).run
      #      if res[:result].failed?
      #        raise DockerImageBuildFailed, "Error building image '#{imageName}' from dockerfile '#{selectedDf}'. Error was : #{res[:errStream].join(" ")}"
      #      end

      #      config.image_name = imageName

      #    end # if image found or not

      #  else
      #    # no Dockerfile found
      #    raise DockerfileNotExist, "No Dockerfile given. Please make sure there is one or run init first"
      #  end # not_empy? selectedDf


      #end

      #def build_image(imageName, selectedDf)

      #  raise DockerImageBuildFailed, "Image name cannot be empty" if is_empty?(imageName)

      #  res = dcFact.find_image(imageName).run
      #  if not res[:result].failed? and is_empty?(res[:outStream])
      #    # image does not exist
      #    res = dcFact.build_image(imageName, dockerfile: selectedDf).run 
      #    if res[:result].failed?
      #      raise DockerImageBuildFailed, "Building image '#{config.image_name}' failed. Error stream : #{res[:errStream].join(" ")}"
      #    end
      #  end

      #end

      private
      def is_image_existed?(name)
        if is_empty?(name)
          false
        else
          res = dcFact.find_image(name).run
          if not res.failed? and res.is_out_stream_empty?
            false
          else
            true
          end
        end
      end

      def delete_docker_image(name)
        if not_empty?(name)
          res = dcFact.delete_image(name).run
          not res.failed?
        else
          true
        end
      end

      def build_docker_image(name, opts = {  })
        raise DockerImageBuildFailed, "Given name to build docker image is empty" if is_empty?(name)

        res = dcFact.build_image(name, opts).run 
        if res.failed?
          raise DockerImageBuildFailed, "Building image '#{config.image_name}' failed. Error stream : #{res[:errStream].join(" ")}"
        end

      end

    end
  end
end
