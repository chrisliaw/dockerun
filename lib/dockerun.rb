# frozen_string_literal: true

require 'toolrack'
require 'teLogger'

require 'colorize'
require 'tty/prompt'

require_relative "dockerun/version"

require_relative 'dockerun/command/dockerun'
require_relative 'dockerun/command/init'
require_relative 'dockerun/command/run'
require_relative 'dockerun/command/reset_image'
require_relative 'dockerun/command/run_new_container'
require_relative 'dockerun/command/remove_container'
require_relative 'dockerun/command/run_new_image'
require_relative 'dockerun/command/stop_container'

require_relative 'dockerun/template/template_writer'
require_relative 'dockerun/template/template_engine'

module Dockerun
  class Error < StandardError; end
  # Your code goes here...

  def self.udebug(msg)
    logger.tdebug(:dockerun, msg) if is_user_debug_on?
  end

  def self.logger
    if @_logger.nil?
      @_logger = TeLogger::Tlogger.new
    end
    @_logger
  end

  def self.is_user_debug_on?
    val = ENV["DOCKERUN_DEBUG"]
    (not val.nil? and val == "true")
  end

end
