# frozen_string_literal: true

require 'fileutils'

require_relative '../lib/dockerun/docker_image_helper'

RSpec.describe Dockerun do
  it "has a version number" do
    expect(Dockerun::VERSION).not_to be nil
  end

  it 'generates template for Dockerfile' do
    
    initCmd = ::Dockerun::Command::Init.new
    res = initCmd.parse(%w[dockerun init .]).run
    
    expect(File.dirname(res) == File.expand_path(".")).to be true
    expect(File.exist?(res)).to be true

  end

  it 'build the image' do
   
    class Driver
      include Dockerun::CommandHelper::DockerImageHelper
    end

    d = Driver.new
    sdf = d.load_dockerfile

    expect(sdf.nil?).to be false



  end

end
