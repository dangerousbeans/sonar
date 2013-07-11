class SonarCookies
  include ::Rack::Utils

  def initialize
    @jar = {}
  end

  def jar uri, cookies = nil
    host = (((uri && uri.host) || ::SonarConstants::DEFAULT_HOST).split('.')[-2..-1]||[]).join('.').downcase
    @jar[host] = cookies if cookies
    @jar[host] ||= []
  end

  def [] name
    cookies = to_hash
    cookies[name] && cookies[name].value
  end

  def []= name, value
    persist '%s=%s' % [name, ::Rack::Utils.escape(value)]
  end

  def delete name
    jar nil, jar(nil).reject { |c| c.name == name }
  end

  def clear
    jar nil, []
  end

  %w[size empty?].each do |m|
    define_method m do |*args|
      jar(nil).send __method__, *args
    end
  end

  def persist raw_cookies, uri = nil
    return unless raw_cookies.is_a?(String)

    # before adding new cookies, lets cleanup expired ones
    jar uri, jar(uri).reject { |c| c.expired? }

    raw_cookies = raw_cookies.strip.split("\n").reject { |c| c.empty? }

    raw_cookies.each do |raw_cookie|
      cookie = Cookie.new(raw_cookie, uri)
      cookie.valid?(uri) || next
      jar(uri, jar(uri).reject { |existing_cookie| cookie.replaces? existing_cookie })
      jar(uri) << cookie
    end
    jar(uri).sort!
  end

  def to_s uri = nil
    to_hash(uri).values.map { |c| c.raw }.join(';')
  end

  def to_hash uri = nil
    jar(uri).inject({}) do |cookies, cookie|
      cookies.merge((uri ? cookie.dispose_for?(uri) : true) ? {cookie.name => cookie} : {})
    end
  end

  class Cookie
    include ::Rack::Utils

    attr_reader :raw, :name, :value, :domain, :path, :expires, :default_host

    def initialize raw, uri
      @default_host = ::SonarConstants::DEFAULT_HOST

      uri ||= default_uri
      uri.host ||= default_host

      @raw, @options = raw.split(/[;,] */n, 2)
      @name, @value = parse_query(@raw, ';').to_a.first
      @options = parse_query(@options, ';')

      @domain = @options['domain'] || uri.host || default_host
      @domain = '.' << @domain unless @domain =~ /\A\./

      @path = @options['path'] || uri.path.sub(/\/[^\/]*\Z/, '')

      (expires = @options['expires']) && (@expires = ::Time.parse(expires))
    end

    def replaces? cookie
      [name.downcase, domain, path] == [cookie.name.downcase, cookie.domain, cookie.path]
    end

    def empty?
      value.nil? || value.empty?
    end

    def secure?
      @options.has_key?('secure')
    end

    def expired?
      expires && expires < ::Time.now.gmtime
    end

    def dispose_for? uri
      expired? ? false : valid?(uri)
    end

    def valid? uri = nil
      uri ||= default_uri
      uri.host ||= default_host

      (secure? ? uri.scheme == 'https' : true) &&
          (uri.host =~ /#{::Regexp.escape(domain.sub(/\A\./, ''))}\Z/i) &&
          (uri.path =~ /\A#{::Regexp.escape(path)}/)
    end

    def <=> cookie
      [name, path, domain.reverse] <=> [cookie.name, cookie.path, cookie.domain.reverse]
    end

    private
    def default_uri
      ::URI.parse('//' << default_host << '/')
    end
  end
end
