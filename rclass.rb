require 'thread'
require 'drb/drb'

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
      q = Queue.new

      Thread.new do
        obj = self.allocate
        obj.__send__(:initialize, *args)
        DRb.start_service('druby://localhost:0', obj)
        q << DRb.uri
        sleep
      end

      uri = q.shift
      DRb.primary_server = nil
      robj = DRbObject.new_with_uri(uri)
      robj
    end
  end
end

