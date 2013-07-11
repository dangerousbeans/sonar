module SonarTest__params

  class App < Air

    def index vars
      self.GET.values_at(*vars.split(',')).inspect
    end

    def post_index vars
      self.POST.values_at(*vars.split(',')).inspect
    end

  end

  Spec.new App do

    before do
      @vars, @vals = 2.times.map { 10.times.map { rand.to_s } }
      @params = Hash[@vars.zip @vals]
    end

    Testing :GET do

      r = get @vars.join(','), @params
      expect(r.body) == @params.values_at(*@vars).inspect

      Should 'mix params [Hash] with query_string [String]' do
        qs_vars, qs_vals = 2.times.map { 10.times.map { rand.to_s } }
        qs_params = Hash[qs_vars.zip qs_vals]
        query_string = ::Rack::Utils.build_query(qs_params)
        r = get((@vars + qs_vars).join(',') << '?' << query_string, @params)
        expect(r.body) == @params.merge(qs_params).values_at(*(@vars + qs_vars)).inspect
      end
    end

    Testing :POST do

      r = post @vars.join(','), @params
      expect(r.body) == @params.values_at(*@vars).inspect

      Should 'have content type set to application/x-www-form-urlencoded' do
        expect(last_request.env['CONTENT_TYPE']) == 'application/x-www-form-urlencoded'
      end
    end

  end
end
