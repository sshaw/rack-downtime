require "date"

class Rack::Downtime
  module Utils
    def parse_downtime(data)
      return unless data

      downtime = data.split("/", 2).map { |date| DateTime.iso8601(date) }
      downtime.empty? ? nil : downtime
    end

    module_function :parse_downtime
  end
end
