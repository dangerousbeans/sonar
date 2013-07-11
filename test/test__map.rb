module SonarTest__map

  class App < Air

    def news a1
      a1
    end

  end

  Spec.new App do

    Testing 'without map' do
      get '/news/1'
      expect(last_response.status) == 200
      expect(last_response.body) == '1'
    end

    When 'setting map' do
      map '/news'

      It 'should work only with arguments' do
        get 1
        expect(last_response.status) == 200
        expect(last_response.body) == '1'
      end

      And 'if map including arguments as well' do
        map '/news/foo'

        It 'should work without arguments' do
          get
          expect(last_response.status) == 200
          expect(last_response.body) == 'foo'
        end
      end
    end

    When 'map cleared' do
      map nil

      It 'should require full url' do
        get
        expect(last_response.status) == 404

        get 'foo'
        expect(last_response.status) == 404

        get '/news/foo'
        expect(last_response.status) == 200
      end
    end

    When 'requests starting with a slash or protocol' do
      map '/blah'

      It 'should ignore base URL set by map' do
        get 'news/foo'
        expect(last_response.status) == 404

        get '/news/foo'
        expect(last_response.status) == 200

        get 'http://blah.org/news/foo'
        is(last_response).not_found?

        header['HTTP_HOST'] = 'blah.org'
        get 'http://blah.org/news/foo'
        is(last_response).ok?
      end
    end
  end
end
