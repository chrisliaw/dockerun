
require 'tty/prompt'

module Dockerun
  module CliHelper
     module CliPrompt
       
       def cli
         if @pmt.nil?
           @pmt = TTY::Prompt.new
         end
         @pmt
       end

     end
  end
end
