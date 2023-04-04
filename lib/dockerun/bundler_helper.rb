
require 'bundler'

module Dockerun
  module CommandHelper
    module BundlerHelper

      def find_local_dev_gems

        res = {}
        Bundler.load.dependencies.each do |d|
          if not d.source.nil?
            src = d.source
            if src.path.to_s != "."
              res[d.name] = src.path.to_s
            end
          end
        end
        res

      end # find_local_dev_gem
      
    end
  end
end
