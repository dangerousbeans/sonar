module SonarTest__session

  class App < Air

    def index
      __method__
    end

  end

  class JustAnotherApp < Air
    def alone
      __method__
    end
  end

  Spec.new self do

    Testing 'manually initialized session' do
      session = SonarSession.new App

      o 'setting headers'
      session.header['User-Agent'] = 'Sonar'

      session.get
      expect(session.last_response.status) == 200
      expect(session.last_response.body) == 'index'

      o 'checking headers'
      is(session.last_request.env['HTTP_USER_AGENT']) == 'Sonar'

      o 'resetting app'
      expect { session.reset_app! }.to_raise_error

      Testing 'app switcher' do
        expect { session.app JustAnotherApp }.to_raise_error

        session = SonarSession.new JustAnotherApp
        session.get
        expect(session.last_response.status) == 404

        session.get :alone
        expect(session.last_response.status) == 200

      end
    end

  end
end
