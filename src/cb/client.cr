require "http/client"
require "json"

class CB::Client
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

  record Cluster, id : String, team_id : String, name : String do
    include JSON::Serializable
  end

  def get_teams
    resp = get "teams"
    Array(Team).from_json resp.body, root: "teams"
  end

  def get_clusters
    resp = get "clusters"
    Array(Cluster).from_json resp.body, root: "clusters"
  end

  def get_cluster(id)
    resp = get "clusters/#{id}"
    JSON.parse resp.body
  end

  record Plan, id : String, display_name : String do
    include JSON::Serializable
  end

  record Region, id : String, display_name : String, location : String do
    include JSON::Serializable
  end

  record Provider, id : String, display_name : String,
    regions : Array(Region), plans : Array(Plan) do
    include JSON::Serializable
  end

  def get_providers
    resp = get "providers"
    Array(Provider).from_json resp.body, root: "providers"
  end

  def get(path)
    resp = HTTP::Client.get("https://#{host}/#{path}", headers: headers)
    if resp.success?
      return resp
    end
    raise "error: #{path} #{resp.status}"
  end
end
