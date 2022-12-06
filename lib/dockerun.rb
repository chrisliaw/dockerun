# frozen_string_literal: true

require 'toolrack'
require 'teLogger'

require_relative "dockerun/version"

require_relative 'dockerun/command/dockerun'
require_relative 'dockerun/command/init'
require_relative 'dockerun/command/run'
require_relative 'dockerun/command/reset_image'
require_relative 'dockerun/command/run_new_container'
require_relative 'dockerun/command/remove_container'
require_relative 'dockerun/command/run_new_image'

require_relative 'dockerun/template/template_writer'
require_relative 'dockerun/template/template_engine'

module Dockerun
  class Error < StandardError; end
  # Your code goes here...
end
