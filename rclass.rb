require 'drb/drb'
require 'socket'

def rclass(klass, &blk)
  cls = nil

  self.class.module_eval <<-EOS
    class #{klass}
    end

    cls = #{klass}
  EOS

  cls.module_eval(&blk)
  cls.module_eval do
    def self.new(*args)
      remote_uri = nil

      TCPServer.open(0) do |server|
        thread_for_remote_uri = Thread.new do
          remote_uri = server.accept.read
        end

        fork do
          obj = self.allocate
          obj.__send__(:initialize, *args)
          DRb.start_service('druby://:0', obj)
          TCPSocket.open('127.0.0.1', server.addr[1]) do |sock|
            sock.write(DRb.uri)
          end
          sleep
        end

        thread_for_remote_uri.join
      end

      DRbObject.new_with_uri(remote_uri)
    end
  end
end

