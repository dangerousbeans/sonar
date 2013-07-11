module SonarTest__redirect

  class App < Air

    def index
      redirect :destination
    end

    def destination
      __method__
    end

  end

  Spec.new App do

    get
    is(last_response.status) == 302

    follow_redirect!
    is(last_response.status) == 200
    is(last_response.body) == 'destination'

    Should 'keep scheme' do
      s_get
      is(last_response.status) == 302

      follow_redirect!
      is(last_request.env['HTTPS']) == 'on'
      is(last_response.status) == 200
      is(last_response.body) == 'destination'
    end

    Should 'raise an error if last response is not an redirect' do
      get :destination
      does { follow_redirect! }.raise_error?
    end

  end
end
