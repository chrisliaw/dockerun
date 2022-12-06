
require 'etc'

module Dockerun

  module UserInfo
    include TR::CondUtils

    def user_info(login = nil)
      login = Etc.getlogin if is_empty?(login)
      res = { login: login }
      begin
        res[:user_id] = Etc.getpwnam(login).uid
      rescue Exception => ex
        res[:user_id] = nil
      end
      res
    end

    def group_info(login = nil)
      login = Etc.getlogin if is_empty?(login)
      res = {  }
      begin
        gnm = Etc.getgrnam(login)
        res[:group_name] = gnm.name
        res[:group_id] = gnm.gid
      rescue Exception => ex
        p ex
        res[:group_name] = ""
        res[:group_id] = nil
      end
      res
    end

  end
  
end
