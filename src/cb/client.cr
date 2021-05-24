require "http/client"
require "json"

struct CB::Client
  def self.get_token(creds : Creds) : Token
    req = {
      "grant_type"    => "client_credential",
      "client_id"     => creds.id,
      "client_secret" => creds.secret,
    }
    resp = HTTP::Client.post("https://#{creds.host}/token", form: req)
    raise resp.status.to_s + resp.body unless resp.status.success?

    parsed = JSON.parse(resp.body)
    token = parsed["access_token"].as_s
    expires_in = parsed["expires_in"].as_i
    expires = Time.local.to_unix + expires_in - 5.minutes.seconds

    Token.new(creds.host, token, expires).store
  end
end
