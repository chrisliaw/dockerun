
require_relative 'cli_prompt'
require_relative 'docker_command_factory_helper'
require_relative 'bundler_helper'
require_relative 'template/template_writer'

module Dockerun
  module CommandHelper
    module DockerImageHelper
      include CliHelper::CliPrompt
      include DockerCommandFactoryHelper
      include BundlerHelper

      class DockerfileNotExist < StandardError; end
      class DockerImageBuildFailed < StandardError; end
      class DockerImageDeleteFailed < StandardError; end
      class DockerImagePrebuiltConfigFailed < StandardError; end

      def load_dockerfile(root = Dir.getwd, dockerInitPath = nil, &block)

        #avail = ::Dockerun::Template::TemplateEngine.available_templates
        df = ::Dockerun::Template::TemplateEngine.available_templates

        #df = Dir.glob(File.join(root,"Dockerfile*"))
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

        tw = ::Dockerun::Template::TemplateWriter.new(selectedDf)
        tw.docker_init_file_path = dockerInitPath
        userFields = tw.user_configurables
        if block
          tw.user_configurables = block.call(:prompt_user_configurables, { template: selectedDf, userFields: userFields })
        end
        res = tw.compile

        loc = "."
        #loc = params[:location] if not_empty?(params[:location])

        loc = File.expand_path(loc)
        out = nil
        if File.directory?(loc)
          out = File.join(loc, "Dockerfile.dockerun")
        else
          out = File.join(File.dirname(loc), "Dockerfile.dockerun")
        end

        File.open(out, "w") do |f|
          f.write res
        end


        #selectedDf
        File.basename(out)
          
      end

      def build_image_if_not_exist(name, &block)
       
        raise DockerImageBuildFailed, "block is required" if not block

        mountPoints = []
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

            #@workspace_root = "/opt"
            #@shared_dirs = {}

            #mount = []
            #sharedInsideDocker = []
            #res = find_local_dev_gems
            #puts "Found #{res.length} local gems #{res}"
            #if not res.empty?

            #  transferMapping = block.call(:transfer_dev_gem_mapping?)
            #  if transferMapping
            #    res.each do |name, path|
            #      tsrc = block.call(:workspace_root_inside_docker, @workspace_root, name, path)
            #      inPath = File.join(tsrc, name)
            #      mount << { path => inPath }
            #      @shared_dirs[name] = inPath 
            #    end
            #  end

            #end

            #mapProjectDir = block.call(:map_project_dir, @workspace_root)
            #if not_empty?(mapProjectDir)
            #  mount << { Dir.getwd => mapProjectDir }
            #end

            #reqVolMap = block.call(:volume_mapping_required?)
            #if reqVolMap

            #  loop do

            #    block.call(:already_mapped, mount)

            #    src = block.call(:source_prompt)
            #    dest = block.call(:destination_prompt, src)
            #    mount << { src => dest }

            #    add_to_bundle = block.call(:add_to_bundle?, dest)
            #    if add_to_bundle
            #      @shared_dirs[File.basename(dest)] = dest
            #    end

            #    block.call(:add_mount_to_container, container_name, mount.last)
            #    repeat = block.call(:add_more_volume_mapping?)
            #    break if not repeat

            #  end

            #end


            #insideDockerConfig = File.join(File.dirname(__FILE__),"..","..","template","setup_ruby_devenv.rb.erb")
            #if File.exist?(insideDockerConfig)

            #  @docker_init_file_path = File.join(Dir.getwd,"on_docker_config")

            #  cont = File.read(insideDockerConfig)

            #  b = binding

            #  res = ERB.new(cont)
            #  out = res.result(b)

            #  # fixed this name to be used inside Dockerfile 
            #  File.open(@docker_init_file_path, "w") do |f|
            #    f.write out
            #  end

            #  block.call(:on_docker_init_file_path,@docker_init_file_path) 

            #end

            mountPoints, dockerinit = prompt_mount_points(&block)


            dockerfile = load_dockerfile(Dir.getwd, dockerinit, &block)
            build_docker_image(name, dockerfile: dockerfile)
          end

        else

            if not is_image_existed?(name)

              mountPoints, dockerinit = prompt_mount_points(&block)

              dockerfile = load_dockerfile(Dir.getwd, dockerinit, &block)
              build_docker_image(name, dockerfile: dockerfile)
            end

        end

        [name, mountPoints]

      end

      def prompt_mount_points(&block)

        raise DockerImagePrebuiltConfigFailed, "block is mandatory" if not block

        @workspace_root = "/opt"
        @shared_dirs = {}

        block.call(:prompt_mount_points_starting)

        mount = []
        res = find_local_dev_gems
        #puts "Found #{res.length} local gems #{res}"
        if not res.empty?

          transferMapping = block.call(:transfer_dev_gem_mapping?, res)
          if transferMapping
            res.each do |name, path|
              tsrc = block.call(:workspace_root_inside_docker, @workspace_root, name, path)
              mount << { path => tsrc }
              @shared_dirs[name] = tsrc 
            end
          end

        end

        mapProjectDir = block.call(:map_project_dir, @workspace_root)
        if not_empty?(mapProjectDir)
          mount << { Dir.getwd => mapProjectDir }
        end

        reqVolMap = block.call(:volume_mapping_required?)
        if reqVolMap

          loop do

            block.call(:already_mapped, mount)

            src = block.call(:source_prompt, { control: [ "Type 's' to skip" ] })
            if src == "s"
              block.call(:volume_mapping_skipped)
              break
            end

            dest = block.call(:destination_prompt, src)
            mount << { src => dest }

            add_to_bundle = block.call(:add_to_bundle?, dest)
            if add_to_bundle
              @shared_dirs[File.basename(dest)] = dest
            end

            block.call(:add_mount_to_container, container_name, mount.last)
            repeat = block.call(:add_more_volume_mapping?)
            break if not repeat

          end

        end


        insideDockerConfig = File.join(File.dirname(__FILE__),"..","..","template","setup_ruby_devenv.rb.erb")
        if File.exist?(insideDockerConfig)

          @docker_init_file_path = File.join(Dir.getwd,"on_docker_config")

          cont = File.read(insideDockerConfig)

          b = binding

          res = ERB.new(cont)
          out = res.result(b)

          # fixed this name to be used inside Dockerfile 
          File.open(@docker_init_file_path, "w") do |f|
            f.write out
          end

          block.call(:on_docker_init_file_path,@docker_init_file_path) 

        end

        [mount, @docker_init_file_path]

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
          raise DockerImageBuildFailed, "Building image '#{name}' failed. Error stream : #{res.err_stream}"
        end

      end

    end
  end
end
