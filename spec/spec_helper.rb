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

RSpec::Matchers.define :eq_ignore do |expect|
  expect.gsub!(/\s{2,}|\n/, "")
  
  match do |actual|
    actual.gsub!(/\s{2,}|\n/, "")                                   
    actual.casecmp(expect) == 0
  end
end
