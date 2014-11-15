# Rack::Downtime

Add planned downtime messages to your responses

## Usage

```ruby
require "rack/downtime"

use Rack::Downtime  # html body
use Rack::Downtime, :insert_at => "body #container"

# Just populate env["rack.downtime"]
use Rack::Downtime, :insert => false

# Get downtime from a cookie -set by a load balancer, of course ;)
use Rack::Downtime, :strategy => :cookie
use Rack::Downtime, :strategy => { :cookie => "my_cookie" }

# Some default config
Rack::Downtime.strategy = :file
Rack::Downtime::Strategy::File.path = Rails.root.join("downtime.txt")

# Disable via Apache config
SetEnv RACK_DOWNTIME_DISABLE 1

# Or, turn of insertion
SetEnv RACK_DOWNTIME_INSERT  0
```
