require 'rubygems'
require 'specular'

$:.unshift ::File.expand_path '../../lib', __FILE__
require 'sonar'

class Air < ::Rack::Request
  class << self

    def use ware = nil, *args, &proc
      @middleware ||= []
      @middleware << [ware, args, proc] if ware
      @middleware
    end

    def map
      @map
    end

    def action_map
      @action_map
    end

    def app root = nil
      if root
        @root = root
      else
        return @app if @app
      end
      map!

      builder, app = ::Rack::Builder.new, self
      use.each do |w|
        ware, args, proc = w
        builder.use ware, *args, &proc
      end
      map.each_key do |route|
        builder.map route do
          run lambda { |env| app.new(env).__air__response__ route }
        end
      end
      @app = builder.to_app
    end

    alias to_app app

    def call env
      app.call env
    end

    def base_url
      @root || '/'
    end

    alias baseurl base_url

    private
    def map!
      @action_map = {}
      @map = self.instance_methods(false).reject { |m| m.to_s =~ /^__air__/ }.inject({}) do |map, meth|
        route, request_method = meth.to_s, 'GET'
        SonarConstants::REQUEST_METHODS.each do |rm|
          regex = /^#{rm}_/i
          route =~ regex && (route = route.sub(regex, '')) && (request_method = rm.upcase) && break
        end

        {'____' => '.',
         '___' => '-',
         '__' => '/'}.each_pair { |f, t| route = route.gsub(f, t) }

        arity = self.instance_method(meth).arity
        setup = [meth, arity < 0 ? -arity - 1 : arity]
        (map[rootify(route)] ||={})[request_method] = setup
        (map[rootify] ||= {})[request_method] = setup if route == 'index'
        @action_map[meth.to_sym] = rootify(route)
        map
      end
    end

    def rootify route = nil
      ('/%s/%s' % [base_url, route]).gsub /\/+/, '/'
    end
  end

  attr_reader :response

  def __air__response__ route
    rsp = catch :__air__halt__ do
      @response = ::Rack::Response.new
      rest_map = self.class.map[route] || halt(404)
      action, required_parameters = rest_map[env['REQUEST_METHOD']] || halt(404)
      arguments = env['PATH_INFO'].to_s.split('/').select { |c| c.size > 0 }
      arguments.size == required_parameters || halt(404, '%s arguments expected, %s given' % [required_parameters, arguments.size])
      response.body = [self.send(action, *arguments).to_s]
      response
    end
    rsp['Content-Type'] ||= 'text/html'
    rsp.finish
  end

  def base_url
    self.class.base_url
  end

  def halt status, message = nil
    response.status = status
    response.body = [message] if message
    throw :__air__halt__, response
  end

  def redirect action_or_path
    response['Location'] = self.class.action_map[action_or_path] || action_or_path
    response.status = 302
    throw :__air__halt__, response
  end

  def permanent_redirect action_or_path
    response['Location'] = self.class.action_map[action_or_path] || action_or_path
    response.status = 301
    throw :__air__halt__, response
  end

  def params
    @__air__params__ ||= indifferent_params(super)
  end

  def get_params
    @__air__get_params__ ||= indifferent_params(self.GET)
  end

  def post_params
    @__air__post_params__ ||= indifferent_params(self.POST)
  end

  private
  def indifferent_params(object)
    case object
      when Hash
        new_hash = indifferent_hash
        object.each { |key, value| new_hash[key] = indifferent_params(value) }
        new_hash
      when Array
        object.map { |item| indifferent_params(item) }
      else
        object
    end
  end

  def indifferent_hash
    Hash.new { |hash, key| hash[key.to_s] if Symbol === key }
  end
end
