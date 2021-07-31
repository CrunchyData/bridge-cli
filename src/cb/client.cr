require "http/client"
require "json"
require "../stdlib_ext"

class CB::Client
  class Error < ::Exception
    property method : String
    property path : String
    property resp : HTTP::Client::Response

    def initialize(@method, @path, @resp)
    end

    def to_s(io : IO)
      io.puts "#{"error".colorize.red.bold}: #{resp.status.code.colorize.cyan} #{resp.status.description.colorize.red}"
      indent = "       "
      io.puts "#{indent}#{method.upcase.colorize.green} to /#{path.colorize.green}"

      begin
        JSON.parse(resp.body).as_h.each do |k, v|
          io.puts "#{indent}#{"#{k}:".colorize.light_cyan} #{v}"
        end
      rescue JSON::ParseException
        io.puts "#{indent}#{resp.body}" unless resp.body == ""
      end
    end

    def unauthorized?
      resp.status == HTTP::Status::UNAUTHORIZED
    end

    def not_found?
      resp.status == HTTP::Status::NOT_FOUND
    end
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
    expires_in = parsed["expires_in"].as_i
    expires = Time.local.to_unix + expires_in - 5.minutes.seconds

    Token.new(creds.host, token, expires).store
  end

  property host : String
  property headers : HTTP::Headers

  def initialize(token : Token)
    @host = token.host
    @headers = HTTP::Headers{
      "Accept"        => "application/json",
      "Authorization" => "Bearer #{token.token}",
      "User-Agent"    => CB::VERSION_STR,
    }
    @http = nil.as(HTTP::Client?)
  end

  # memoize to avoid slow tests
  def http : HTTP::Client
    h = @http || HTTP::Client.new(host, tls: self.class.tls)
    @http ||= h
    h
  end

  jrecord Team, id : String, name : String, is_personal : Bool, roles : Array(Int32) do
    enum Role
      Member
      Manager
      Administrator
    end

    def name
      is_personal ? "personal" : @name
    end

    def human_roles
      roles.map { |i| Role.new i }
    end
  end

  jrecord Cluster, id : String, team_id : String, name : String

  jrecord ClusterDetail,
    id : String,
    team_id : String,
    name : String,
    state : String,
    created_at : Time,
    cpu : Int32,
    is_ha : Bool,
    major_version : Int32,
    plan_id : String,
    memory : Int32,
    oldest_backup : Time?,
    provider_id : String,
    region_id : String,
    storage : Int32

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
    ClusterDetail.from_json resp.body, root: "cluster"
  rescue e : Error
    raise e unless e.resp.status == HTTP::Status::FORBIDDEN
    raise Program::Error.new "cluster #{id.colorize.t_id} does not exist, or you do not have access to it"
  end

  jrecord Role, name : String, password : String, uri : URI

  def get_cluster_default_role(id)
    resp = get "clusters/#{id}/roles/default"
    Role.from_json resp.body
  end

  def create_cluster(cc)
    body = {
      ha:            cc.ha,
      major_version: 13,
      name:          cc.name,
      plan_id:       cc.plan,
      provider_id:   cc.platform,
      region_id:     cc.region,
      storage:       cc.storage,
      team_id:       cc.team,
    }
    resp = post "clusters", body
    Cluster.from_json resp.body, root: "cluster"
  end

  def destroy_cluster(id)
    delete "clusters/#{id}"
  end

  jrecord Plan, id : String, display_name : String
  jrecord Region, id : String, display_name : String, location : String
  jrecord Provider, id : String, display_name : String,
    regions : Array(Region), plans : Array(Plan)

  def get_providers
    resp = get "providers"
    Array(Provider).from_json resp.body, root: "providers"
  end

  jrecord FirewallRule, id : String, rule : String

  def get_firewall_rules(cluster_id)
    resp = get "clusters/#{cluster_id}/firewall"
    Array(FirewallRule).from_json resp.body, root: "firewall_rules"
  end

  def delete_firewall_rule(cluster_id, firewall_rule_id)
    delete "clusters/#{cluster_id}/firewall/#{firewall_rule_id}"
  end

  def add_firewall_rule(cluster_id, cidr)
    post "clusters/#{cluster_id}/firewall", {rule: cidr}
  end

  jrecord Logdest, id : String, host : String, port : Int32, template : String, description : String

  def get_logdests(cluster_id)
    resp = get "clusters/#{cluster_id}/loggers"
    Array(Logdest).from_json resp.body, root: "loggers"
  end

  def add_logdest(lda : CB::LogdestAdd)
    resp = post "clusters/#{lda.cluster_id}/loggers", {
      host:        lda.host,
      port:        lda.port,
      template:    lda.template,
      description: lda.desc,
    }
    resp.body
  end

  def destroy_logdest(cluster_id, logdest_id)
    resp = delete "clusters/#{cluster_id}/loggers/#{logdest_id}"
    resp.body
  end

  def get(path)
    exec "GET", path
  end

  def post(path, body)
    exec "POST", path, body
  end

  def put(path, body)
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
    return resp if resp.success?
    raise Error.new(method, path, resp)
  end

  def self.tls
    OpenSSL::SSL::Context::Client.new.tap do |client|
      {% if flag?(:darwin) %}
        # workaround: Can't easily build for arm macs, so they use the
        # statically linked x86 under rosetta. This however seems to hardcode
        # the homebrew location of the tls certs, which will fail unless they
        # have happened to install openssl with homebrew
        client.ca_certificates = "/private/etc/ssl/cert.pem"
      {% end %}
    end
  end
end
