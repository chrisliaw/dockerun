
require_relative 'docker_command_factory_helper'

module Dockerun
  module CommandHelper
    module DockerContainerHelper
      include DockerCommandFactoryHelper

      class DockerContainerBuildFailed < StandardError; end
      class DockerContainerStartFailed < StandardError; end

      def run_docker_container(image_name, container_name, &block)
     
        raise DockerContainerBuildFailed, "block is required" if not block
        raise DockerContainerBuildFailed, "Image name is required" if is_empty?(image_name)

        reuse = nil

        if is_empty?(container_name)
          container_name = block.call(:new_container_name)
          loop do
            st, _ = is_container_exist?(container_name)
            if st
              reuse = block.call(:container_name_exist, container_name)
              break if reuse
              container_name = block.call(:new_container_name)
            else
              break
            end
          end

        else
          st, _ = is_container_exist?(container_name)
          if st
            reuse = true
          else
            # if not found shall drop into the next block's else clause 
          end
        end

        if reuse == true
         
          res = dcFact.find_running_container(container_name).run
          if not res.failed? and res.is_out_stream_empty?
            # not running
            ress = dcFact.start_container(container_name).run
            raise DockerContainerStartFailed, "Failed to start container '#{container_name}'. Error was : #{ress.err_stream}" if ress.failed?
          end

          dcFact.attach_container(container_name).run

        else

          reqVolMap = block.call(:volume_mapping_required?)
          mount = []
          if reqVolMap

            loop do

              src = block.call(:source_prompt)
              dest = block.call(:destination_prompt)
              mount << { src => dest }
              block.call(:add_mount_to_container, container_name, mount.last)
              repeat = block.call(:add_more_volume_mapping?)
              break if not repeat

            end

          end

          dcFact.create_container_from_image(image_name, interactive: true, tty: true, container_name: container_name, mount: mount).run

        end

        container_name

      end

      private
      def is_container_exist?(name)
        if not_empty?(name)
          res = dcFact.find_from_all_container(name).run
          raise DockerContainerBuildFailed, "Failed to find container. Error was : #{res.err_stream}" if res.failed?

          if res.is_out_stream_empty?
            # nothing found
            [false, ""]
          else
            [true, res.out_stream]
          end
        else
          [false, nil]
        end
      end

      def run_container(name)

        res = dcFact.start_container(name)
        raise DockerContainerStartFailed, "Failed to start docker container name '#{name}'. Error was : #{res.err_stream}" if res.failed?

      end

      
    end
  end
end
