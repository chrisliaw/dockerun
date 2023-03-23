
require 'docker/cli'

module Dockerun

  # 
  # Link to CommandFactory 
  #
  module DockerCommandFactoryHelper
    
    def dcFact
      if @dcFact.nil?
        @dcFact = Docker::Cli::CommandFactory.new
      end
      @dcFact
    end

  end
end
