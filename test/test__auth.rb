module SonarTest__auth

  class Basic < Air

    use Rack::Auth::Basic do |u, p|
      [u, p] == ['user', 'pass']
    end

    def index
      __method__
    end

    def post_index
      __method__
    end

  end

  class Digest < Air

    use Rack::Auth::Digest::MD5, 'AccessRestricted', rand.to_s do |u|
      {'digest-user' => 'digest-pass'}[u]
    end

    def index
      __method__
    end

    def post_index
      __method__
    end

  end

  Spec.new self do

    Testing :Basic do
      app Basic

      r = get
      expect(r.status) == 401

      auth 'user', 'pass'
      r = get
      expect(r.status) == 200
      expect(r.body) == 'index'

      o 'reset auth using `reset_auth!`'
      reset_auth!

      r = get
      expect(r.status) == 401

      o 'relogin'
      auth 'user', 'pass'
      r = get
      expect(r.status) == 200
      expect(r.body) == 'index'

      o 'reset auth using `reset_basic_auth!`'
      reset_basic_auth!

      r = get
      expect(r.status) == 401

      o 'relogin'
      auth 'user', 'pass'
      r = get
      expect(r.status) == 200
      expect(r.body) == 'index'

      Should 'fail with wrong credentials' do
        reset_basic_auth!

        auth 'bad', 'guy'
        r = get
        expect(r.status) == 401
      end

      Should 'auth via POST' do
        reset_basic_auth!

        auth 'user', 'pass'
        r = post
        expect(r.status) == 200
        expect(r.body) == 'post_index'
      end
    end

    Testing :Digest do
      app Digest

      r = get
      expect(r.status) == 401

      digest_auth 'digest-user', 'digest-pass'
      r = get
      expect(r.status) == 200
      expect(r.body) == 'index'

      o 'reset auth using `reset_auth!`'
      reset_digest_auth!

      r = get
      expect(r.status) == 401

      o 'relogin'
      digest_auth 'digest-user', 'digest-pass'
      r = get
      expect(r.status) == 200
      expect(r.body) == 'index'

      o 'reset auth using `reset_basic_auth!`'
      reset_digest_auth!

      r = get
      expect(r.status) == 401

      o 'relogin'
      digest_auth 'digest-user', 'digest-pass'
      r = get
      expect(r.status) == 200
      expect(r.body) == 'index'

      Should 'fail with wrong credentials' do
        reset_digest_auth!

        digest_auth 'bad', 'guy'
        r = get
        expect(r.status) == 401
      end

      Should 'auth via POST' do
        reset_digest_auth!

        digest_auth 'digest-user', 'digest-pass'
        r = post
        expect(r.status) == 200
        expect(r.body) == 'post_index'
      end
    end

  end
end
