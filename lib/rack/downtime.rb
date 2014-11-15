require "rack"
require "nokogiri"

require "rack/downtime/strategy"
require "rack/downtime/version"

module Rack
  class Downtime    
    DOWNTIME_DISABLE = "RACK_DOWNTIME_DISABLE".freeze
    DOWNTIME_INSERT = "RACK_DOWNTIME_INSERT".freeze    

    ENV_KEY = "rack.downtime".freeze
    # Newer versions of Rack should have there
    CONTENT_TYPE = "Content-Type".freeze
    CONTENT_LENGTH = "Content-Length".freeze

    DEFAULT_LOCATION = "html body".freeze
    DEFAULT_MESSAGE =<<HTML.freeze # ERB?
<div class="rack-downtime-container"><p class="rack-downtime-message">Downtime scheduled from %s to %s. Sorry for any inconvenience.</p></div>
HTML

    def initialize(app, options = {})
      @app = app

      #@strategy = options[:strategy] || self.class.strategy || FILE_STRATEGY
      @strategy = options[:strategy] || FILE_STRATEGY      
      @strategy = load_strategy(@strategy) unless @strategy.respond_to?(:call)
      
      @message = options[:message] || DEFAULT_MESSAGE
      @insert = options[:insert] || true
      @insert_at = options[:insert_at] || DEFAULT_LOCATION
    end

    def call(env)
      return @app.call(env) if ENV[DOWNTIME_DISABLE] == "1"
      
      downtime = get_downtime(env)
      env[ENV_KEY] = downtime   

      response = @app.call(env)
      return response if downtime && insert_downtime?(response[1])

      old_body = response[2]
      new_body = insert_downtime(old_body, downtime)

      old_body.close if old_body.respond_to?(:close)
      response[1][CONTENT_LENGTH] = Rack::Util.bytesize(new_body)
      response[2] = new_body

      response
    end

    private

    def load_strategy(options)
      name, config = options.first
      case name
      when :cookie
        Strategy::Cookie.new(config)
      when :file
        Strategy::File.new(config)
      when :query
        Strategy::Query.new(config)
      else
        raise ArgumentError, "unknown strategy: #{name}"
      end
    end
    
    def get_downtime(req)
      @strategy.call(Rack::Request.new(env))
    end
    
    def insert_downtime?(headers)
      ENV[DOWNTIME_INSERT] != "0" && @insert && headers[CONTENT_TYPE] =~ /html/
    end
    
    def insert_downtime(old_body, times)
      new_body = ""
      old_body.each { |line| new_body << line }

      doc = Nokogiri::HTML(new_body)
      e = doc.at(@insert_at)
      return new_body unless e
      
      e.before(sprintf(@message, *times))

      # This will insert doctype if none is there
      doc.to_html
    end
  end

end
end
