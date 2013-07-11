module SonarTest__request_methods

  class App < Air

    def index
      body
    end

    def post_index
      body
    end

    def put_index
      body
    end

    def patch_index
      body
    end

    def head_index
      body
    end

    def delete_index
      body
    end

    def options_index
      body
    end

    def trace_index
      body
    end

    private
    def body
      [request_method, port, ssl?, xhr?].inspect
    end

  end

  Spec.new App do

    SonarConstants::REQUEST_METHODS.each do |rm|
      r = self.send(rm.downcase)
      expect(r.status) == 200
      expect(r.body) == [rm, 80, false, false].inspect
    end

    Testing :SSL do
      SonarConstants::REQUEST_METHODS.each do |rm|
        r = self.send('s_' + rm.downcase)
        expect(r.status) == 200
        expect(r.body) == [rm, 443, true, false].inspect
      end
    end

    Testing :XHR do
      SonarConstants::REQUEST_METHODS.each do |rm|
        r = self.send(rm.downcase + '_x')
        expect(r.status) == 200
        expect(r.body) == [rm, 80, false, true].inspect
      end
    end

    Testing :SecureXHR do
      SonarConstants::REQUEST_METHODS.each do |rm|
        r = self.send('s_' + rm.downcase + '_x')
        expect(r.status) == 200
        expect(r.body) == [rm, 443, true, true].inspect
      end
    end
  end
end
