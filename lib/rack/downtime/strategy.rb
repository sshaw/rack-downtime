require "rack/request"
require "rack/utils"
require "rack/downtime/utils"

class Rack::Downtime
  module Strategy
    class Cookie
      include Rack::Utils
      
      class << self
        attr_writer :named

        def named
          @@named ||= "__dt__"
        end
      end

      def initialize(named = nil)
        @named = named || self.class.named
      end

      def call(env)
        req = Rack::Request.new(env)
        Rack::Downtime::Utils.parse_downtime(req.cookies[@named])
        #delete_cookie_header!(env, @named) if downtime
        #downtime
      end
    end

    class Query
      class << self
        attr_writer :param

        def param
          @@param ||= "__dt__"
        end
      end

      def initialize(param = nil)
        @param = param || self.class.param
      end

      def call(env)
        req = Rack::Request.new(env)
        Rack::Downtime::Utils.parse_downtime(req[@param])
      end
    end

    class File
      class << self
        attr_writer :path

        def path
          @@path ||= "downtime.txt"
        end
      end

      def initialize(path = nil)
        @path  = path || self.class.path
        @mtime = 0
      end

      def call(env)
        return unless ::File.exists?(@path)

        new_mtime = ::File.mtime(@path).to_i
        if new_mtime > @mtime
          @downtime = parse_downtime(@path)
          @mtime = new_mtime
        end

        @downtime
      end

      private

      def parse_downtime(path)
        Rack::Downtime::Utils.parse_downtime(::File.read(path))
      end
    end
  end
end
