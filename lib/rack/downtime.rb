require "rack"
require "erb"
require "nokogiri"

require "rack/downtime/strategy"
require "rack/downtime/version"

module Rack
  class Downtime
    DOWNTIME_DISABLE = "RACK_DOWNTIME_DISABLE".freeze
    DOWNTIME_INSERT = "RACK_DOWNTIME_INSERT".freeze

    ENV_KEY = "rack.downtime".freeze
    DEFAULT_INSERT_AT = "html body".freeze
   
    # Newer versions of Rack should have these
    CONTENT_TYPE = "Content-Type".freeze
    CONTENT_LENGTH = "Content-Length".freeze

    class << self
      attr_writer :strategy

      def strategy
        @@strategy ||= :file
      end
    end

    def initialize(app, options = {})
      @app = app

      @strategy = options[:strategy] || self.class.strategy
      @strategy = load_strategy(@strategy) unless @strategy.respond_to?(:call)

      @insert = options[:insert]
      @insert = load_template(@insert) if @insert

      @insert_at = options[:insert_at] || DEFAULT_INSERT_AT
    end

    def call(env)
      return @app.call(env) if ENV[DOWNTIME_DISABLE] == "1"

      downtime = get_downtime(env)
      env[ENV_KEY] = downtime if downtime

      response = @app.call(env)
      return response unless downtime && insert_downtime?(response)

      old_body = response[2]
      new_body = insert_downtime(old_body, downtime)

      old_body.close if old_body.respond_to?(:close)
      response[1][CONTENT_LENGTH] = Rack::Utils.bytesize(new_body).to_s
      response[2] = [new_body]

      response
    end

    private

    def load_strategy(options)
      config = nil
      strategy = options
      strategy, config = strategy.first if strategy.is_a?(Hash)

      case strategy
      when :cookie
        Strategy::Cookie.new(config)
      when :file
        Strategy::File.new(config)
      when :query
        Strategy::Query.new(config)
      else
        raise ArgumentError, "unknown strategy: #{strategy}"
      end
    end

    def load_template(template)
      Class.new do
        include ERB.new(::File.read(template), nil, "<>%-").def_module("render(start_date, end_date)")
      end.new
    end

    def get_downtime(env)
      @strategy.call(env)
    end

    def insert_downtime?(response)
      response[0] == 200 && ENV[DOWNTIME_INSERT] != "0" && @insert && response[1][CONTENT_TYPE] =~ /html/
    end

    def insert_downtime(old_body, times)
      new_body = ""
      old_body.each { |line| new_body << line }

      doc = Nokogiri::HTML(new_body)
      e = doc.at(@insert_at)
      return new_body unless e
      
      message = @insert.render(*times)
      
      if e.child
        e.child.before(message)
      else
        e.add_child(message)
      end

      doc.to_html
    end
  end
end
