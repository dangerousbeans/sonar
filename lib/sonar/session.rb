class SonarSession

  include ::Sonar

  attr_reader :headers, :cookies, :last_request, :last_response
  alias header headers

  def initialize app
    app.respond_to?(:call) ||
        raise('app should be a valid Rack app')

    @app = app
    @headers, @cookies = {}, ::SonarCookies.new
  end

  def basic_authorize user, pass
    @basic_auth = [user, pass]
  end

  alias authorize basic_authorize
  alias auth basic_authorize

  def digest_authorize user, pass
    @digest_auth = [user, pass]
  end

  alias digest_auth digest_authorize

  def reset_basic_auth!
    @basic_auth = nil
  end

  def reset_digest_auth!
    @digest_auth = nil
  end

  def reset_auth!
    reset_basic_auth!
    reset_digest_auth!
  end

  def invoke_request request_method, uri, params, env

    default_env = ::SonarConstants::DEFAULT_ENV.dup.merge(env)
    default_env.update :method => request_method
    default_env.update :params => params
    default_env.update 'HTTP_COOKIE' => cookies.to_s(uri)
    default_env.update basic_auth_header

    process_request uri, default_env

    if @digest_auth && @last_response.status == 401 && (challenge = @last_response['WWW-Authenticate'])
      default_env.update digest_auth_header(challenge, uri.path, request_method)
      process_request uri, default_env
    end

    cookies.persist(@last_response.header['Set-Cookie'], uri)

    @last_response.respond_to?(:finish) && @last_response.finish
    @last_response
  end

  def __sonar__session__
    self
  end

  def reset_app!
    raise 'It makes no sense to use `%s` with manually created sessions. To test another app, just create a new session.' % __method__
  end

  alias reset_browser! reset_app!

  def app *args
    args.any? && raise('It makes no sense to use `%s` with manually created sessions. To test another app, just create a new session.' % __method__)
    @app
  end

  private
  def process_request uri, env
    env = ::Rack::MockRequest.env_for(uri.to_s, env.dup)
    explicit_env = headers_to_env
    explicit_env['rack.input'] &&
        env['REQUEST_METHOD'] == 'POST' && env.delete('CONTENT_TYPE')
    env.update explicit_env

    @last_request = ::Rack::Request.new(env)

    # initializing params. do not remove! needed for nested params to work
    @last_request.params

    status, headers, body = app.call(@last_request.env)

    @last_response = ::Rack::MockResponse.new(status, headers, body, env['rack.errors'].flush)
    body.respond_to?(:close) && body.close
  end

  def headers_to_env
    headers.keys.inject({}) do |headers, key|
      value = headers()[key]
      if (key =~ /\A[[:upper:]].*\-?[[:upper:]]?.*?/) && (key !~ /\AHTTP_|\ACONTENT_TYPE\Z/)
        key = (key == 'Content-Type' ? '' : 'HTTP_') << key.upcase.gsub('-', '_')
      end
      headers.merge key => value
    end
  end

  def basic_auth_header
    (auth = @basic_auth) ?
        {'HTTP_AUTHORIZATION' => 'Basic %s' % ["#{auth.first}:#{auth.last}"].pack("m*")} :
        {}
  end

  def digest_auth_header challenge, uri, request_method
    params = ::Rack::Auth::Digest::Params.parse(challenge.split(" ", 2).last)
    params.merge!({
                      "username" => @digest_auth.first,
                      "nc" => "00000001",
                      "cnonce" => "nonsensenonce",
                      "uri" => uri,
                      "method" => request_method,
                  })
    params["response"] = MockDigestRequest.new(params).response(@digest_auth.last)
    {'HTTP_AUTHORIZATION' => 'Digest ' << params.map {|p| '%s="%s"' % p}.join(', ')}
  end

  class MockDigestRequest # stolen from rack-test

    def initialize(params)
      @params = params
    end

    def method_missing(sym)
      if @params.has_key? k = sym.to_s
        return @params[k]
      end

      super
    end

    def method
      @params['method']
    end

    def response(password)
      Rack::Auth::Digest::MD5.new(nil).send :digest, self, password
    end

  end

end
