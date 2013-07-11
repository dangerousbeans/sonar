require 'rubygems'
require 'uri'
require 'rack'


module SonarConstants

  REQUEST_METHODS = %w[GET POST PUT PATCH DELETE OPTIONS HEAD TRACE].freeze
  SESSION_METHODS = %w[
    header headers cookies last_request last_response
    auth authorize basic_authorize digest_auth digest_authorize
    reset_auth! reset_basic_auth! reset_digest_auth!
  ].freeze
  DEFAULT_HOST = 'sonar.org'.freeze
  DEFAULT_ENV = {'REMOTE_ADDR' => '127.0.0.1', 'HTTP_HOST' => DEFAULT_HOST}.freeze
end

module Sonar

  # switch session
  #
  # sonar using app based sessions, that's it, creates sessions based on app __id__.
  # you can test multiple apps and use `app RackApp` to switch between them.
  #
  def app app = nil
    @__sonar__app__ = app if app
    @__sonar__app__
  end

  def map *args
    @__sonar__base_url__ = args.first if args.size > 0
    @__sonar__base_url__
  end

  # reset session for current app.
  # everything will be reset - cookies, headers, authorizations etc.
  def reset_app!
    __sonar__session__ :reset
  end

  alias reset_browser! reset_app!

  ::SonarConstants::REQUEST_METHODS.each do |request_method|
    define_method request_method.downcase do |*args|
      params = args.last.is_a?(Hash) ? args.pop : {}
      request :http, request_method, args.compact.join('/'), params
    end
    # secure
    define_method 's_%s' % request_method.downcase do |*args|
      params = args.last.is_a?(Hash) ? args.pop : {}
      request :https, request_method, args.compact.join('/'), params
    end
    # xhr
    define_method '%s_x' % request_method.downcase do |*args|
      params = args.last.is_a?(Hash) ? args.pop : {}
      request :http, request_method, args.compact.join('/'), params, {'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest'}
    end
    # secure xhr
    define_method 's_%s_x' % request_method.downcase do |*args|
      params = args.last.is_a?(Hash) ? args.pop : {}
      request :https, request_method, args.compact.join('/'), params, {'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest'}
    end
  end

  ::SonarConstants::SESSION_METHODS.each do |m|
    define_method m do |*args|
      __sonar__session__.send m, *args
    end
  end

  def request scheme, request_method, uri, params, env = {}
    uri = [@__sonar__base_url__, uri].compact.join('/') unless uri =~ /\A\/|\A[\w|\d]+\:\/\//
    uri = ::URI.parse(uri.gsub(/\A\/+/, '/'))
    uri.scheme ||= scheme.to_s
    uri.host ||= ::SonarConstants::DEFAULT_HOST
    uri.path = '/' << uri.path unless uri.path =~ /\A\//
    params.is_a?(Hash) && params.each_pair do |k, v|
      (v.is_a?(Numeric) || v.is_a?(Symbol)) && params.update(k => v.to_s)
    end
    __sonar__session__.invoke_request request_method, uri, params, env
  end

  def follow_redirect!
    last_response.redirect? ||
        raise('Last response is not an redirect!')
    scheme = last_request.env['HTTPS'] == 'on' ? 'https' : 'http'
    request scheme, 'GET', last_response['Location'], {}, {'HTTP_REFERER' => last_request.url}
  end

  def __sonar__session__ reset = false
    (@__sonar__session__ ||= {})[app.__id__] = ::SonarSession.new(app) if reset
    (@__sonar__session__ ||= {})[app.__id__] ||= ::SonarSession.new(app)
  end
end

require 'sonar/cookies'
require 'sonar/session'
