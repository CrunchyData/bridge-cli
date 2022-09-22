require "http/client"
require "json"
require "log"
require "promise"
require "../ext/stdlib_ext"

module CB
  class Client
    property host : String
    property headers : HTTP::Headers
    getter token : Token

    def initialize(@token : Token)
      @host = token.host
      @headers = HTTP::Headers{
        "Accept"        => "application/json",
        "Authorization" => "Bearer #{token.token}",
        "User-Agent"    => CB::VERSION_STR,
      }

      ENV.select { |k, _| k.starts_with? "X_CRUNCHY_" }.each { |k, v|
        @headers.add k.split('_').map(&.titleize).join('-'), v
      }
    end

    def self.get_token(creds : Creds) : Token
      req = {
        "grant_type"    => "client_credential",
        "client_id"     => creds.id,
        "client_secret" => creds.secret,
      }
      resp = HTTP::Client.post("https://#{creds.host}/token", form: req, tls: tls)
      raise Error.new("post", "token", resp) unless resp.status.success?

      parsed = JSON.parse(resp.body)
      token = parsed["access_token"].as_s
      expires = begin
        expires_in = parsed["expires_in"].as_i
        Time.local.to_unix + expires_in - 5.minutes.seconds
      rescue
        # on 2021-09-09 the API started returning a number that caused int overflow
        (Time.local + 10.minutes).to_unix
      end

      tmp_token = Token.new(creds.host, token, expires, "", "")

      account = new(tmp_token).get_account

      Token.new(creds.host, token, expires, account.id, account.name).store
    end

    def http : HTTP::Client
      HTTP::Client.new(host, tls: self.class.tls)
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
      resp = http.exec method, "http://#{host}/#{path}", headers: headers, body: body
      Log.info &.emit("API Call", status: resp.status.code, path: path, method: method)
      if resp.body && ENV["HTTP_DEBUG"]?
        body = mabye_json_parse resp.body
        status = resp.status.code
        pp! [method, path, status, body] # ameba:disable Lint/DebugCalls
      end

      return resp if resp.success?
      raise Error.new(method, path, resp)
    end

    def self.tls
      OpenSSL::SSL::Context::Client.new.tap do |client|
        cert_file = SSL_CERT_FILE
        client.ca_certificates = cert_file if cert_file
      end
    end

    private def mabye_json_parse(str)
      JSON.parse str
    rescue
      str
    end
  end
end
