
<a href="https://travis-ci.org/waltee/sonar">
<img src="https://travis-ci.org/waltee/sonar.png" align="right"></a>

# Sonar

**API for Testing Rack Apps with easy**

## Install

```bash
$ [sudo] gem install sonar
```

## Load

```ruby
require 'sonar'
```

## Use

Simply `include Sonar` in your tests.

Or use it directly, by initialize a session via `SonarSession.new`

## App

When mixin used, call `app RackApp` inside testing suite to set app to be tested.

**Minitest Example:**

```ruby
require 'sonar'

class MyTests < MiniTest::Unit::TestCase

    include Sonar

    def setup
        app MyRackApp
    end

    def test
        get '/url'
        assert_equal last_response.status, 200
    end
end
```

**[Specular](https://github.com/waltee/specular) Example:**

```ruby
Spec.new do
    app MyRackApp

    get '/url'
    expect(last_response.status) == 200
end
```

Multiple apps can be tested within same suite.<br/>
Each app will run own session.

**Minitest Example:**

```ruby
require 'sonar'

class MyTests < MiniTest::Unit::TestCase

    include Sonar

    def setup
        app MyRackApp
    end

    def test
        # querying default app
        get '/url'
        assert_equal last_response.status, 200

        # testing ForumApp
        app ForumApp
        get '/posts'
        assert_equal last_response.status, 200

        # back to default app
        app MyRackApp
        get '/url'
        assert_equal last_response.status, 200
    end
end
```

When using session manually, you should set app at initialization.

**Example:**

```ruby
session = SonarSession.new MyRackApp
session.get '/url'
assert_equal session.last_response.status, 200
```


## Resetting App

Sometimes you need to start over with a new app in pristine state, i.e. no cookies, no headers etc.

To achieve this, simply call `reset_app!` (or `reset_browser!`).

This will reset currently tested app. Other tested apps will stay untouched.

When creating sessions manually, app can NOT be switched/reset.<br/>
To test another app, simply create another session.

## Requests

Use one of `get`, `post`, `put`, `patch`, `delete`, `options`, `head`
to make requests via Sonar browser.

To make a secure request, add `s_` prefix:

```ruby
s_get  '/path'
s_post '/path'
# etc.
```

To make a request via XHR, aka Ajax, add `_x` suffix:

```ruby
get_x  '/path'
post_x '/path'
# etc.
```

To make a secure request via XHR, add both `s_` and `_x`:

```ruby
s_get_x  '/path'
s_post_x '/path'
# etc.
```

In terms of arguments, making HTTP requests via Sonar is identical to calling regular Ruby methods.<br/>
That's it, you do not need to join parameters into a string.<br/>
Just pass them as usual arguments:

```ruby
post '/news', :create, :title => rand
post '/news', :update, id, :title => rand
get  '/news', :delete, id
```

## Map

Previous example works just fine, however it is redundant and inconsistent.<br/>
Just imagine that tested app changed its base URL from /news to /headlines.

The solution is simple.<br/>
Use `map` to define a base URL that will be prepended to each request,<br/>
except ones starting with a slash or a protocol(http://, https:// etc.) of course.

```ruby
Spec.new do
    app MyRackApp
    map '/news'

    post :create, :title => rand
    post :update, id, :title => rand
    get  :delete, id
end
```

**Note:** requests starting with a slash or protocol(http://, https:// etc.)
wont use base URL defined by `map`.<br/>

**Note:** when you switching tested app, make sure you also change the map.

To disable mapping, simply call `map nil`

## Cookies

**Set cookies:**

```ruby
cookies['name'] = 'value'
```

**Read cookies:**

```ruby
cookie = cookies['name']
```

**Delete a cookie:**

```ruby
cookies.delete 'name'
```


**Clear all cookies:**

```ruby
cookies.clear
```

Each app uses its own cookies jar.

## Headers

Sonar allow to set headers that will be sent to app on all consequent requests.

**Set headers:**

```ruby
header['User-Agent']   = 'Sonar'
header['Content-Type'] = 'text/plain'
header['rack.input']   = 'someString'
# etc.
```

**Read headers:**

```ruby
header = headers['User-Agent']
# etc.
```

**Delete a header:**

```ruby
headers.delete 'User-Agent'
```

**Clear all headers:**

```ruby
headers.clear
```

Each app uses its own headers.

## Authorization

**Basic Auth:**

```ruby
authorize 'user', 'pass'
```

**Reset earlier set Basic authorization header:**

```ruby
reset_basic_auth!
```

**Digest Auth:**

```ruby
digest_authorize 'user', 'pass'
```

**Reset earlier set Digest authorization header:**

```ruby
reset_digest_auth!
```

**Reset ANY earlier set authorization header:**

```ruby
reset_auth!
```

## Follow Redirects

By default, Sonar wont follow redirects.

If last response is a redirect and you want Sonar to follow it, use `follow_redirect!`
