require "rspec"
require "rack/test"
require "rack/downtime"

RSpec.configure do |c|
  c.include Module.new {
    def time_interval(times)
      times.map { |d| d.strftime("%FT%X%Z") }.join("/")
    end
      
    def new_app(response = {})  
      code    = response[:code]    || 200
      headers = response[:headers] || {}
      body    = response[:body]    || "<!DOCTYPE html><html><body><p>Content!</p></body></html>"

      headers["Content-Length"]||= body.size
      headers["Content-Type"]  ||= "text/html"
      
      ->(env) do
        yield env if block_given?

        [code, headers, [body]]
      end
    end
  }
end

# Poor man's TestXml
RSpec::Matchers.define :eq_html do |expect|  
  match do |actual|
    Nokogiri::HTML(expect).to_html == Nokogiri::HTML(actual).to_html
  end
end
