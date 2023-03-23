
require_relative 'docker_command_factory_helper'

module Dockerun
  module CommandHelper

    # 
    # Common functions for docker container management
    #
    module DockerContainerHelper
      include DockerCommandFactoryHelper

      class DockerContainerBuildFailed < StandardError; end
      class DockerContainerStartFailed < StandardError; end
      class DockerContainerStopFailed < StandardError; end

      def run_docker_container(image_name, container_name, &block)
     
        raise DockerContainerBuildFailed, "block is required" if not block
        raise DockerContainerBuildFailed, "Image name is required" if is_empty?(image_name)

        Dockerun.udebug("Running image '#{image_name}', container '#{container_name}'")

        reuse = nil

        if is_empty?(container_name)
          Dockerun.udebug "Container name empty. Creating new container"
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
          reuse, _ = is_container_exist?(container_name)
          Dockerun.udebug "Container name not empty. Is container exist? : #{reuse}"
          #if st
          #  reuse = true
          #else
          #  # if not found shall drop into the next block's else clause 
          #end
        end

        if reuse == true
        
          Dockerun.udebug "Find out of container '#{container_name}' is running..." 
          #res = dcFact.find_running_container(container_name).run
          #if not res.failed? and res.is_out_stream_empty?
          if not is_container_running?(container_name)
            # not running
            Dockerun.udebug "Container '#{container_name}' does not seems to be running. Starting container."
            ress = dcFact.start_container(container_name).run
            raise DockerContainerStartFailed, "Failed to start container '#{container_name}'. Error was : #{ress.err_stream}" if ress.failed?
          end

          ucmd = cli.ask("Command to be run inside the container. Empty to attach to existing session : ", value: "/bin/bash")
          if is_empty?(ucmd)
            dcFact.attach_container(container_name).run
          else
            dcFact.run_command_in_running_container(container_name, ucmd, tty: true, interactive: true).run
          end

        else

          Dockerun.udebug "Container '#{container_name}' doesn't exist. Proceed to create new container."
          reqVolMap = block.call(:volume_mapping_required?)
          mount = block.call(:existing_volume_mapping) || []
          #mount = []
          if reqVolMap

            loop do

              src = block.call(:source_prompt)
              dest = block.call(:destination_prompt, src)
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

      def is_container_running?(name)
        if not_empty?(name)
          res = dcFact.find_running_container(name).run
          not res.failed? and not res.is_out_stream_empty?
        else
          false
        end
      end

      def stop_container(name)
        res = dcFact.stop_container(name).run
        raise DockerContainerStopFailed, "Failed to stop docker container '#{name}'. Error was : #{res.err_stream}" if res.failed?
      end

      
    end
  end
end
