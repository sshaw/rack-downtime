require "rack/downtime/util"

class Rack::Downtime
  module Strategy
    class Cookie
      def self.name=(name)
        @@name = name
      end
      
      def initialize(name = nil)
        @name = name || @@name
      end

      def call(req)
        downtime = Rack::Downtime::Util.parse_downtime(req.cookies[name])
        if downtime
          # Need to remove from here too?
          # req.env["rack.request.cookie_string"]
          req.cookies.delete(name)
        end

        downtime
      end
    end

    class Query
      def self.param=(param)
        @@param = param
      end
      
      def initialize(param = nil)
        @param = param || @@param
      end

      def call(req)
        Rack::Downtime::Util.parse_downtime(req.params[@param])
      end
    end

    class File
      def self.path=(path)
        @@path = path
      end
      
      def initialize(path = nil)
        @path  = path || @@path
        @mtime = 0
      end

      def call(req)
        return unless File.exists?(@path)

        new_mtime = File.mtime(@path)
        if new_mtime > @mtime
          downtime = parse_downtime(@path)
          @mtime = new_mtime
        end

        downtime
      end

      private

      def parse_downtime(path)
        Rack::Downtime::Util.parse_downtime(File.read(path))
      end
    end
  end
end
