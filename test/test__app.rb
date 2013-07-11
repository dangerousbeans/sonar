module SonarTest__app

  class App < Air

    def index
      __method__
    end

  end

  class JustAnotherApp < Air
    def another
      __method__
    end
  end

  Spec.new App do

    get
    expect(last_response.status) == 200
    expect(last_response.body) == 'index'

    Testing :cookies do
      cookies['foo'] = 'bar'
      expect(cookies['foo']) == 'bar'
    end

    Testing :headers do
      header['User-Agent'] = 'Sonar'
      expect(headers['User-Agent']) == 'Sonar'
    end


    When 'switching app' do
      app JustAnotherApp

      It 'should use own cookies jar' do
        is(cookies['foo']).nil?
      end

      And 'own headers' do
        is(headers['User-Agent']).nil?
      end

      get
      expect(last_response.status) == 404

      get :another
      expect(last_response.status) == 200
    end

    When 'switching back to default app' do
      app App

      It 'should have previously cookies set' do
        expect(cookies['foo']) == 'bar'
      end

      And :headers do
        expect(headers['User-Agent']) == 'Sonar'
      end

      get
      expect(last_response.status) == 200

      get :another
      expect(last_response.status) == 404
    end

  end
end
