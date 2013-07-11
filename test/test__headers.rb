module SonarTest__headers

  class App < Air

    def index headers
      env.values_at(*headers.split(',')).inspect
    end

    def post_index
      content_type
    end

    def dry
    end

    def post_dry
    end

  end

  Spec.new App do

    Testing 'User-Agent' do
      reset_app!

      ua = 'Chrome'
      header['User-Agent'] = ua
      r = get 'HTTP_USER_AGENT'
      is(r.body) == [ua].inspect

      ua = 'Safari'
      header['User-Agent'] = ua
      r = get 'HTTP_USER_AGENT'
      is(r.body) == [ua].inspect
    end

    Testing 'Content-Type' do
      reset_app!

      ct = 'text/plain'
      header['Content-Type'] = ct
      r = get 'CONTENT_TYPE'
      expect(r.body) == [ct].inspect

      Should 'not override explicit CONTENT_TYPE on POST requests' do

        ct = 'text/plain'
        header['Content-Type'] = ct
        r = post
        expect(r.body) == ct
      end
    end

    Should 'have 127.0.0.1 as default REMOTE_ADDR' do
      reset_app!

      get
      expect(last_request.env['REMOTE_ADDR']) == '127.0.0.1'
    end

    Should 'have sonar.org as default SERVER_NAME' do
      reset_app!

      get
      expect(last_request.env['SERVER_NAME']) == 'sonar.org'
    end

    Setting 'Rack-related headers' do
      reset_app!

      When 'setting rack.input explicitly' do

        It 'should override default rack.input' do
          header['rack.input'] = StringIO.new('someString')
          get :dry
          expect(last_request.env['rack.input']) == header['rack.input']
        end

        And 'not add multipart content type on post requests' do
          post :dry
          refute(last_request.env['CONTENT_TYPE']) =~ /x\-www\-form\-urlencoded/
        end
      end

      Should 'keep explicitly set rack.errors' do
        errors = StringIO.new
        header['rack.errors'] = errors
        get
        expect { last_request.env['rack.errors'].__id__ } == errors.__id__
      end
    end

  end
end
