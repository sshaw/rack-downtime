# Rack::Downtime

Planned downtime management for Rack applications

[![Build Status](https://travis-ci.org/sshaw/rack-downtime.svg?branch=master)](https://travis-ci.org/sshaw/rack-dowmtime)
[![Code Climate](https://codeclimate.com/github/sshaw/rack-downtime/badges/gpa.svg)](https://codeclimate.com/github/sshaw/rack-downtime)

## Overview

`Rack::Dowtime` **does not** add a maintenance page -there are *plenty* of ways to do this already. Instead,
it provides one with a variety of simple ways to trigger and takedown planned maintenance notifications while a site
**is still up**.

### Examples

```ruby
require "rack/downtime"

use Rack::Downtime
```

In your layout:

```erb
<% if ENV.include?("rack.downtime") %>
  <div>
    <p>
      We will be down for maintenance on
	  <%= ENV["rack.downtime"][0].strftime("%b %e") %> from
	  <%= ENV["rack.downtime"][0].strftime("%l:%M %p") %> to
	  <%= ENV["rack.downtime"][1].strftime("%l:%M %p") %> EST.
	</p>
  </div>
<% end %>
```

Now set the downtime using the `:file` strategy:

```
# 1 to 4 AM
> echo '2014-11-15T01:00/2014-11-15T04:00' > downtime.txt
```

If you prefer, `Rack::Downtime` can insert the message for you:

```ruby
# Inserts a downtime message
use Rack::Downtime, :insert => "my_template.erb"

# Specify where to insert message
use Rack::Downtime, :insert => "my_template.erb", :insert_at => "body #container"
```

The downtime can be set various ways:

```ruby
# From the HTTP header X-Downtime
use Rack::Downtime, :strategy => :header
use Rack::Downtime, :strategy => { :header => "X-MyHeader" }

# Or from the query string
use Rack::Downtime, :strategy => :query
use Rack::Downtime, :strategy => { :query => "dwn__" }
```

Alternate configuration:

```ruby
Rack::Downtime.strategy = :file
Rack::Downtime::Strategy::File.path = Rails.root.join("downtime.txt")
```

Control its behavior via environment variables:

```
SetEnv RACK_DOWNTIME 2014-11-15T01:00:00-05/2014-11-15T04:00:00-05

# Disable
SetEnv RACK_DOWNTIME_DISABLE 1

# Or, just turn of insertion
SetEnv RACK_DOWNTIME_INSERT  0
```

## Usage

Downtime can be retrieved from various locations via a [downtime strategy](#downtime-strategies). When downtime is detected,
it's turned into 2 instances of `DateTime` and added to the Rack environment at `rack.downtime`. The 0th
element is the start time and the 1st element is the end time.

The dates must be given as an [ISO 8601 time interval](https://en.wikipedia.org/wiki/ISO_8601#Time_intervals)
in `start/end` format. If no dates are found `rack.downtime` will not be set.

Downtime messages can also be added to the response's body. See *[Inserting a Downtime Message](#inserting-a-downtime-message)*.

### Downtime Strategies

Strategies are given via the `:strategy` option. If none is provided then `Rack::Downtime.strategy`
is used, which defaults to `:file`.

#### `:file`

Looks in the current directory for a file named `downtime.txt`. 

```ruby
use Rack::Downtime :strategy => :file
```

To use a file named `my_file.txt`:

```ruby
use Rack::Downtime :strategy => { :file => "my_file.txt" }
```

#### `:query`

Looks for a query string parameter named `__dt__`.

```ruby
use Rack::Downtime :strategy => :query
```

To use a query string named `q`:

```ruby
use Rack::Downtime :strategy => { :query => "q" }
```

#### `:header`

Looks for an HTTP header named `X-Downtime`.

```ruby
use Rack::Downtime :strategy => :header
```
To look for a header named `X-DT-4SHO`:

```ruby
use Rack::Downtime :strategy => { :header => "X-DT-4SHO" }
```

Internally the header will be converted to match
[what rack generates](http://www.rubydoc.info/github/rack/rack/master/file/SPEC#The_Environment), e.g., `HTTP_*`.

#### `:env`

Looks for an environment variable named `RACK_DOWNTIME`.

#### `:cookie`

Looks for cookie named `__dt__`.

```ruby
use Rack::Downtime :strategy => :cookie
```
To use a cookie named `oreo`:

```ruby
use Rack::Downtime :strategy => { :cookie => "oreo" }
```

#### Custom

Just pass in something that responds to `:call`, accepts a rack environment, and returns a [downtime array](#usage).

```ruby
use Rack::Downtime :strategy => ->(env) { YourDownTimeConfig.find_dowmtime }
```

### Inserting a Downtime Message

A message can be inserted by `Rack::Downtime` into your response's body whenever downtime is scheduled.
Just provide a path to an ERB template to the `:insert` option. The downtime will be passed to the template
as `start_time` and `end_time`.

By default the template will be inserted after the `body` tag. This can be changed by providing the
desired location to the `:insert_at` option. The location can be given as a CSS selector or an XPath location.

Messages are only inserted into HTML responses with a `200` status code.

**Note that when `Rack::Downtime` inserts a message it will turn a streaming response into a buffered one**.
If this is a problem you can always check for and insert the downtime yourself in your application.

## TODO

Don't invalidate XHTML responses when inserting a downtime message.

## Author

Skye Shaw [sshaw AT gmail.com]
