require "spec_helper"
require "fileutils"

describe Rack::Downtime do

  before do
    @tmp = Dir.mktmpdir
    Dir.chdir(@tmp)

    @dates = [ DateTime.new(2014,11,11,0,0), DateTime.new(2014,11,11,2,0) ]
    @downtime = time_interval(@dates)
    File.write("downtime.txt", @downtime)
  end

  after { FileUtils.rm_f(@tmp) }

  it "sets the environment's rack.downtime to the downtime" do
    set_dates = nil
    app = new_app { |env| set_dates = env["rack.downtime"] }
    req = Rack::Test::Session.new(described_class.new(app))
    req.get "/"

    expect(set_dates).to eq @dates
  end

  # context "when no downtime has been specified" do
  #   it "does not insert the alert"
  #   it "does not assign any dates to rack.downtime"
  # end

  context "given a downtime message template" do
    before do
      @template = File.join(@tmp, "alert.erb")
      File.write(@template, "__HERE__")
    end

    #it "sets the environment's rack.downtime to the downtime"

    context "with a non-200 response" do
      it "does not insert the template" do
        app = new_app(:code => 302)

        req = Rack::Test::Session.new(described_class.new(app, :insert => @template))
        req.get "/"

        expect(req.last_response.body).to_not match("__HERE__")
      end
    end

    context "with a non-HTML content type" do
      it "does not insert the template" do
        app = new_app(:headers => {"Content-Type" => "text/plain"})

        req = Rack::Test::Session.new(described_class.new(app, :insert => @template))
        req.get "/"

        expect(req.last_response.body).to_not match("__HERE__")
      end
    end


    context "when RACK_DOWNTIME_INSERT = 0" do
      before { ENV["RACK_DOWNTIME_INSERT"] = "0"  }
      after  { ENV.delete("RACK_DOWNTIME_INSERT") }

      it "does not insert the template" do
        req = Rack::Test::Session.new(described_class.new(new_app, :insert => @template))
        req.get "/"

        expect(req.last_response.body).to_not match("__HERE__")
      end

      #it "sets the environment's rack.downtime to the downtime"
    end

    it "insets the template into the response" do
      req = Rack::Test::Session.new(described_class.new(new_app, :insert => @template))
      req.get "/"

      expect(req.last_response.body).to eq_ignore "<!doctype html><html><body>__HERE__<p>Content!</p></body></html>"
    end

    it "passes downtime times to the template" do
      File.write(@template, "<%= start_date.hour %>/<%= end_date.hour %>")

      req = Rack::Test::Session.new(described_class.new(new_app, :insert => @template))
      req.get "/"

      expect(req.last_response.body).to eq_ignore "<!doctype html><html><body>0/2<p>Content!</p></body></html>"
    end

    describe "the :insert_at option" do
      [["CSS", "body p"], ["xpath", "//body/p"]].each do |format, location|
        it "insets the template at the given #{format} location" do
          req = Rack::Test::Session.new(described_class.new(new_app, :insert => @template, :insert_at => location))
          req.get "/"

          expect(req.last_response.body).to match(%r{<body><p>__HERE__Content!</p>})
        end
      end

      context "given an invalid location" do
        it "does not insert the template into response" do
          req = Rack::Test::Session.new(described_class.new(new_app, :insert => @template, :insert_at => "div span a"))
          req.get "/"

          expect(req.last_response.body).to_not match("__HERE__")
        end
      end
    end
  end

  describe "strategies" do
    before do
      @app = lambda { |env|
        body = env["rack.downtime"].map { |t| t.strftime("%s") }.join("/")
        headers = {"Content-Type" => "text/plain"}
        headers["Content-Length"] = body.size

        [ 200, headers, [body] ]
      }
      @body = @dates.map { |d| d.strftime("%s") }.join("/")
    end

    describe ":cookie" do
      before { @downtime = Rack::Utils.escape(@downtime) }

      it "sets the downtime from the default cookie name" do
        req = Rack::Test::Session.new(described_class.new(@app, :strategy => :cookie))
        req.set_cookie "__dt__=#@downtime"
        req.get "/"

        expect(req.last_response.body).to eq(@body)
      end

      it "sets the downtime from the given cookie name" do
        req = Rack::Test::Session.new(described_class.new(@app, :strategy => { :cookie => "QWERTY" }))
        req.set_cookie "QWERTY=#@downtime"
        req.get "/"

        expect(req.last_response.body).to eq(@body)
      end


      # context "with a new default name" do
      #   before { Rack::Downtime::Strategy::Cookie.named = "xxx" }
      #   after  { Rack::Downtime::Strategy::Cookie.named = nil }


      #     req = Rack::Test::Session.new(described_class.new(@app, :strategy => :cookie))
      #     req.set_cookie "__dt__=#@downtime" # esc?
      #     req.get "/"

      #     expect(req.last_response.body).to eq(@body)
      #   end
      # end
    end

    describe ":query" do
      it "sets the downtime from the default query string param" do
        req = Rack::Test::Session.new(described_class.new(@app, :strategy => :query))
        req.get "/", :__dt__ => @downtime

        expect(req.last_response.body).to eq(@body)
      end

      it "sets the downtime from the given query string param" do
        req = Rack::Test::Session.new(described_class.new(@app, :strategy => { :query => "param" }))
        req.get "/", :param => @downtime

        expect(req.last_response.body).to match(@body)
      end
    end

    describe ":file" do
      it "sets the downtime from the default downtime files" do
        path = File.join(@tmp, "im_goin_dooooown.txt")
        File.write(path, @downtime)

        req = Rack::Test::Session.new(described_class.new(@app, :strategy => { :file => path }))
        req.get "/"

        expect(req.last_response.body).to eq(@body)
      end

      describe "when the downtime file is updated" do
        it "detects the new downtimes" do
          req = Rack::Test::Session.new(described_class.new(@app, :strategy => { :file => "downtime.txt" }))
          req.get "/"

          @dates[1] = DateTime.new(2014,12,31)
          new_body = @dates.map { |d| d.strftime("%s") }.join("/")
          new_downtime = time_interval(@dates)

          # So we have a different mtime
          sleep 1
          File.write("downtime.txt", new_downtime)

          req.get "/"

          expect(req.last_response.body).to eq(new_body)
        end
      end
    end
  end
end
