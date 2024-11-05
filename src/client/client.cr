require "http/client"
require "json"
require "log"
require "promise"
require "../ext/stdlib_ext"

module CB
  class Client
    property headers : HTTP::Headers
    property host : String

    def initialize(@host : String = CB::HOST, bearer_token : String? = nil)
      @headers = HTTP::Headers{
        "Accept"     => "application/json",
        "User-Agent" => CB::VERSION_STR,
      }

      @headers["Authorization"] = "Bearer #{bearer_token}" if bearer_token

      ENV.select { |k, _| k.starts_with? "X_CRUNCHY_" }.each { |k, v|
        @headers.add k.split('_').map(&.titleize).join('-'), v
      }
    end

    def get_access_token : CB::Model::AccessToken
      secret = Credentials.get

      unless secret && secret.starts_with?("cbkey_")
        STDERR << "error".colorize.t_warn << ": You're using an invalid API key. " \
                                             "You can procure a new one via the dashboard to continue: " \
                                             "https://#{DASHBOARD_HOST}/account/api-keys\n"
        exit 1
      end

      req = {
        "grant_type"    => "client_credential",
        "client_secret" => secret,
      }

      resp = HTTP::Client.post("https://#{host}/access-tokens", form: req, tls: tls)
      raise Error.new("post", "token", resp) unless resp.status.success?

      CB::Model::AccessToken.from_json(resp.body)
    end

    def http : HTTP::Client
      HTTP::Client.new(@host, tls: self.tls)
    end

    def get(path)
      exec "GET", path
    end

    def patch(path, body)
      exec "PATCH", path, body
    end

    def post(path, body = nil)
      exec "POST", path, body
    end

    def put(path, body = nil)
      exec "PUT", path, body
    end

    def delete(path)
      exec "DELETE", path
    end

    def exec(method, path, body)
      exec method, path, body.to_json
    end

    def exec(method, path, body : String? = nil)
      resp = http.exec method, "http://#{@host}/#{path}", headers: headers, body: body
      Log.info &.emit("API Call", status: resp.status.code, path: path, method: method)
      if resp.body && ENV["HTTP_DEBUG"]?
        body = maybe_json_parse resp.body
        status = resp.status.code
        pp! [method, path, status, body] # ameba:disable Lint/DebugCalls
      end

      return resp if resp.success?
      raise Error.new(method, path, resp)
    end

    private def tls
      OpenSSL::SSL::Context::Client.new.tap do |client|
        cert_file = SSL_CERT_FILE
        client.ca_certificates = cert_file if cert_file
      end
    end

    private def maybe_json_parse(str)
      JSON.parse str
    rescue
      str
    end
  end
end
