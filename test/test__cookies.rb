module SonarTest__cookies

  class App < Air

    def index names
      cookies.values_at(*names.split(',')).inspect
    end

    def post_index
      post_params.each_pair do |n, v|
        v.is_a?(Hash) &&
            (expires = v['expires']) &&
            (v['expires'] = ::Time.parse(expires))
        response.set_cookie n, v
      end
    end

    def delete_index names
      names.split(',').each do |n|
        response.delete_cookie n, params[n] || {}
      end
    end

    def post_deeper__path
      post_params.each_pair { |n, v| response.set_cookie n, v }
    end

    def deeper name
      cookies[name]
    end

  end

  Spec.new App do

    Testing 'via HTTP' do

      before do
        @var, @val = 2.times.map { 5.times.map { (('a'..'z').to_a + ('A'..'Z').to_a + (1..50).to_a)[rand(100)] }.join }
        @expected, @expected_nil = [@val].inspect, [nil].inspect
      end

      Should 'persist/dispose cause by default cookie`s path is set to current URI path' do
        post @var => @val
        o 'persisted?'
        is(cookies[@var]) == @val
        o 'disposed?'
        r = get @var
        expect(r.body) == @expected
      end

      Should 'persist/dispose cause given path matches default cookie`s path' do
        post @var => {:value => @val, :path => '/'}
        o 'persisted?'
        is(cookies[@var]) == @val
        o 'disposed?'
        r = get @var
        expect(r.body) == @expected
      end

      Should 'NOT persist/dispose cause wrong path provided - /blah is not a prefix of /' do
        post @var => {:value => @val, :path => '/blah'}
        o 'persisted?'
        is(cookies[@var]).nil?
        o 'disposed?'
        r = get @var
        expect(r.body) == @expected_nil
      end

      Should 'persist/dispose cause /deeper is a prefix of /deeper/path' do
        post '/deeper/path', @var => @val
        o 'persisted?'
        is(cookies[@var]) == @val
        o 'disposed?'
        r = get '/deeper', @var
        expect(r.body) == @val
      end

      Should 'NOT persist but not dispose cause path set automatically to /deeper, and it is not a prefix for /' do
        post '/deeper/path', @var => @val
        o 'persisted?'
        is(cookies[@var]) == @val
        o 'disposed?'
        r = get @var
        expect(r.body) == @expected_nil

        Should 'dispose for /deeper path', :hooks => nil do

          r = get '/deeper', @var
          expect(r.body) == @val
        end
      end

      Should 'persist/dispose cause path set to /' do
        post '/deeper/path', @var => {:value => @val, :path => '/'}
        o 'persisted?'
        is(cookies[@var]) == @val
        o 'disposed?'
        r = get @var
        expect(r.body) == @expected
      end

      Should 'NOT dispose - expires is in past' do
        post @var => {:value => @val, :expires => ::Rack::Utils.rfc2822(::Time.now.gmtime - 1)}
        o 'disposed?'
        r = get @var
        expect(r.body) == @expected_nil
      end

      Should 'NOT persist/dispose cause inner domain given' do
        post @var => {:value => @val, :domain => 'x.org'}
        o 'persisted?'
        is(cookies[@var]).nil?
        o 'disposed?'
        r = get @var
        expect(r.body) == @expected_nil
      end

      Should 'persist/dispose - domains matches' do
        host = 'random.tld'

        header['HTTP_HOST'] = host
        post 'http://' + host, @var => @val
        o 'disposed?'

        header['HTTP_HOST'] = host
        r = get 'http://' + host, @var
        expect(r.body) == @expected
        headers.delete 'HTTP_HOST'

        Should 'NOT dispose cause requested from foreign domain' do
          r = get @var
          expect(r.body) == @expected_nil

          header['HTTP_HOST'] = 'x.org'
          r = get 'http://x.org', @var
          expect(r.body) == @expected_nil
          headers.delete 'HTTP_HOST'
        end
      end

      Should 'use separate jar for each domain' do
        header['HTTP_HOST'] = 'foo.bar'
        domain = 'http://' + header['HTTP_HOST']
        o domain
        post domain, 'var' => domain
        r = get domain, 'var'
        expect(r.body) == [domain].inspect
        headers.delete 'HTTP_HOST'

        header['HTTP_HOST'] = 'bar.foo'
        domain = 'http://' + header['HTTP_HOST']
        o domain
        post domain, 'var' => domain
        r = get domain, 'var'
        expect(r.body) == [domain].inspect
        headers.delete 'HTTP_HOST'

        header['HTTP_HOST'] = 'foo.bar'
        domain = 'http://' + header['HTTP_HOST']
        o domain
        r = get domain, 'var'
        expect(r.body) == [domain].inspect
        headers.delete 'HTTP_HOST'

        And 'use same jar for a domain and its subdomains' do
          %w[a  b  c  a.b  a.b.c].each do |subdomain|
            header['HTTP_HOST'] = '%s.foo.bar' % subdomain
            domain = 'http://' + header['HTTP_HOST']
            o domain
            r = get domain, 'var'
            expect(r.body) == ['http://foo.bar'].inspect
            headers.delete 'HTTP_HOST'
          end
        end

        And 'domains names are case insensitive' do
          %w[BAR.foo  bar.FOO   BAR.FOO].each do |host|
            header['HTTP_HOST'] = host
            domain = 'http://' + header['HTTP_HOST']
            o domain
            r = get domain, 'var'
            expect(r.body) == ['http://bar.foo'].inspect
            headers.delete 'HTTP_HOST'
          end
        end

      end

      Should 'prefer more specific cookies' do
        domain = 'http://foo.bar'
        subdomain = 'http://a.foo.bar'

        header['HTTP_HOST'] = 'a.foo.bar'
        post subdomain, 'var' => subdomain

        header['HTTP_HOST'] = 'foo.bar'
        post domain, 'var' => domain

        r = get domain, 'var'
        expect(r.body) == [domain].inspect

        header['HTTP_HOST'] = 'a.foo.bar'
        r = get subdomain, 'var'
        expect(r.body) == [subdomain].inspect
        headers.delete 'HTTP_HOST'
      end

      Should 'NOT persist/dispose cause secure cookie are accessed via un-secure connection' do
        post @var => {:value => @val, :secure => 'true'}
        o 'persisted?'
        is(cookies[@var]).nil?
        o 'disposed?'
        r = get @var
        expect(r.body) == @expected_nil
      end

      Should 'persist/dispose cause secure cookie are accessed via secure connection' do
        s_post @var => {:value => @val, :secure => 'true'}
        o 'persisted?'
        is(cookies[@var]) == @val
        o 'disposed?'
        r = s_get @var
        expect(r.body) == @expected
      end

      Should 'delete a cookie' do
        o 'setting'
        post @var => @val
        r = get @var
        is(r.body) == @expected

        o 'deleting'
        delete @var
        r = get @var
        expect(r.body) == @expected_nil
      end

      Should 'set/get multiple cookies at once' do
        vars, vals = 2.times.map { 5.times.map { 5.times.map { ('a'..'z').to_a[rand(26)] }.join } }
        params = Hash[vars.zip vals]
        post params
        r = get vars.join(',')
        expect(r.body) == params.values_at(*vars).inspect
      end
    end

    Testing :directly do

      n, size = 10, cookies.size
      n.times do
        var, val = 2.times.map { 5.times.map { ('a'..'z').to_a[rand(26)] }.join }
        cookies[var] = val
        expect(cookies[var]) == val
      end
      expect(cookies.size) == size + n

      Should 'delete a cookie' do

        cookies['foo'] = 'bar'
        expect(cookies['foo']) == 'bar'

        cookies.delete 'foo'
        refute(cookies['foo']) == 'bar'
        is(cookies['foo']).nil?
      end

      Should 'clear cookies' do
        cookies.clear
        expect(cookies.size) == 0
      end

      Should 'escape values' do
        cookies['var'] = 'foo;bar'
        expect(cookies['var']) == 'foo;bar'

        cookies['var'] = ';bar;foo;'
        expect(cookies['var']) == ';bar;foo;'
      end

    end

  end
end
