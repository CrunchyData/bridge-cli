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

  property host : String
  property headers : HTTP::Headers

  def initialize(token : Token)
    @host = token.host
    @headers = HTTP::Headers{"Accept" => "application/json", "Authorization" => "Bearer #{token.token}"}
  end

  record Team, id : String, team_name : String, is_personal : Bool, roles : Array(Int32) do
    include JSON::Serializable
    enum Role
      Member
      Manager
      Administrator
    end

    def name
      is_personal ? "personal" : team_name
    end

    def human_roles
      roles.map { |i| Role.new i }
    end
  end

  def get_teams
    resp = HTTP::Client.get("https://#{host}/teams", headers: headers)
    Array(Team).from_json resp.body, root: "teams"
  end
end
