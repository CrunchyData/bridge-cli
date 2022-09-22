require "http/client"
require "json"
require "log"
require "promise"
require "../ext/stdlib_ext"

class CB::Client
  class Error < ::Exception
    Log = ::Log.for("client")

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

    def bad_request?
      resp.status == HTTP::Status::BAD_REQUEST
    end

    def forbidden?
      resp.status == HTTP::Status::FORBIDDEN
    end

    def not_found?
      resp.status == HTTP::Status::NOT_FOUND
    end

    def unauthorized?
      resp.status == HTTP::Status::UNAUTHORIZED
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

  def http : HTTP::Client
    HTTP::Client.new(host, tls: self.class.tls)
  end

  #
  # Message
  #
  jrecord Message, message : String = ""

  #
  # Account
  #

  jrecord Account,
    id : String,
    name : String,
    email : String

  # https://crunchybridgeapi.docs.apiary.io/#reference/0/account/get-account
  def get_account
    resp = get "account"
    Account.from_json resp.body
  end

  # Upgrade operation.
  jrecord Operation, flavor : String, state : String

  #
  # Teams
  #

  # A team is a small organizational unit in Bridge used to group multiple users
  # at varying levels of privilege.
  jrecord Team,
    id : String,
    name : String,
    is_personal : Bool,
    role : String?,
    billing_email : String? = nil,
    enforce_sso : Bool? = nil do
    def name
      is_personal ? "personal" : @name
    end

    def to_s(io : IO)
      io << id.colorize.t_id << " (" << name.colorize.t_name << ")"
    end
  end

  # Create a new team.
  #
  # https://crunchybridgeapi.docs.apiary.io/#reference/0/teams/create-team
  def create_team(name : String)
    resp = post "teams", {name: name}
    Team.from_json resp.body
  end

  # List available teams.
  #
  # https://crunchybridgeapi.docs.apiary.io/#reference/0/teams/list-teams
  def get_teams
    resp = get "teams"
    Array(Team).from_json resp.body, root: "teams"
  end

  # Update a team.
  #
  # https://crunchybridgeapi.docs.apiary.io/#reference/0/teamsteamid/update-team
  def update_team(id, options)
    # TODO: (abrightwell) would it be better to have options bound to a type?
    # Seems like it would be the 'safer' option maybe. Thoughts are around
    # perhaps something like `TeamUpdateOptions`.
    resp = patch "teams/#{id}", options
    Team.from_json resp.body
  end

  # Retrieve details about a team.
  #
  # https://crunchybridgeapi.docs.apiary.io/#reference/0/teamsteamid/get-team
  def get_team(id)
    resp = get "teams/#{id}"
    Team.from_json resp.body
  end

  # Delete a team.
  #
  # https://crunchybridgeapi.docs.apiary.io/#reference/0/teamsteamid/destroy-team
  def destroy_team(id)
    resp = delete "teams/#{id}"
    Team.from_json resp.body
  end

  def get_team_cert(id)
    resp = get "teams/#{id}.pem"
    resp.body
  end

  #
  # Team Members
  #

  # A team member is a association of a bridge user to a bridge team.
  jrecord TeamMember,
    id : String,
    team_id : String,
    account_id : String,
    role : String,
    email : String

  # Parameters required for adding a user to a team.
  jrecord TeamMemberCreateParams, email : String, role : String

  # Create (add) a team member.
  #
  # https://crunchybridgeapi.docs.apiary.io/#reference/0/teamsteamidmembers/create-team-member
  def create_team_member(team_id, params : TeamMemberCreateParams)
    resp = post "teams/#{team_id}/members", params
    TeamMember.from_json resp.body
  end

  # List the memebers of a team.
  #
  # https://crunchybridgeapi.docs.apiary.io/#reference/0/teamsteamidmembers/list-team-members
  def list_team_members(team_id)
    resp = get "teams/#{team_id}/members"
    Array(TeamMember).from_json resp.body, root: "team_members"
  end

  # Retrieve details about a team member.
  #
  # https://crunchybridgeapi.docs.apiary.io/#reference/0/teamsteamidmembersaccountid/get-team-member
  def get_team_member(team_id, account_id)
    resp = get "teams/#{team_id}/members/#{account_id}"
    TeamMember.from_json resp.body
  end

  # Update a team member.
  #
  # https://crunchybridgeapi.docs.apiary.io/#reference/0/teamsteamidmembersaccountid/update-team-member
  def update_team_member(team_id, account_id, role)
    resp = put "teams/#{team_id}/members/#{account_id}", {role: role}
    TeamMember.from_json resp.body
  end

  # Remove a team member from a team.
  #
  # https://crunchybridgeapi.docs.apiary.io/#reference/0/teamsteamidmembersaccountid/remove-team-member
  def remove_team_member(team_id, account_id)
    resp = delete "teams/#{team_id}/members/#{account_id}"
    TeamMember.from_json resp.body
  end

  jrecord Cluster, id : String, team_id : String, name : String,
    replicas : Array(Cluster)?

  def get_clusters
    get_clusters(get_teams)
  end

  def get_clusters(teams : Array(Team))
    Promise.map(teams) { |t| get_clusters t.id }.get.flatten.sort_by!(&.name)
  end

  def get_clusters(team_id : String)
    resp = get "clusters?team_id=#{team_id}"
    team_clusters = Array(Cluster).from_json resp.body, root: "clusters"
    replicas = Array(Cluster).new
    team_clusters.map(&.replicas).reject(Nil).each { |rs| replicas += rs }

    team_clusters + replicas
  end

  jrecord ClusterDetail,
    id : String,
    team_id : String,
    name : String,
    state : String?,
    created_at : Time,
    cpu : Int32,
    host : String,
    is_ha : Bool,
    plan_id : String,
    major_version : Int32,
    memory : Int32,
    oldest_backup : Time?,
    provider_id : String,
    network_id : String,
    region_id : String,
    storage : Int32 do
    @[JSON::Field(key: "cluster_id")]
    getter source_cluster_id : String?
  end

  # Retrieve the cluster by id or by name.
  def get_cluster(id : Identifier)
    return get_cluster id.to_s if id.eid?
    get_cluster_by_name(id)
  end

  private def get_cluster_by_name(id : Identifier)
    cluster = get_clusters.find { |c| id == c.name }
    raise Program::Error.new "cluster #{id.to_s.colorize.t_name} does not exist." unless cluster
    get_cluster cluster.id
  end

  # TODO (abrightwell): track down why this must be nilable. Seems reasonable
  # that it shouldn't require it to be.
  def get_cluster(id : String?)
    resp = get "clusters/#{id}"
    ClusterDetail.from_json resp.body
  rescue e : Error
    raise e unless e.resp.status == HTTP::Status::FORBIDDEN
    raise Program::Error.new "cluster #{id.colorize.t_id} does not exist, or you do not have access to it"
  end

  # https://crunchybridgeapi.docs.apiary.io/#reference/0/clusters/post
  def create_cluster(cc)
    body = {
      is_ha:               cc.ha,
      name:                cc.name,
      plan_id:             cc.plan,
      provider_id:         cc.platform,
      postgres_version_id: cc.postgres_version,
      region_id:           cc.region,
      storage:             cc.storage,
      team_id:             cc.team,
      network_id:          cc.network,
    }
    resp = post "clusters", body
    Cluster.from_json resp.body
  end

  def detach_cluster(id)
    put "clusters/#{id}/detach", ""
  end

  # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridforks/post
  def fork_cluster(cc)
    resp = post "clusters/#{cc.fork}/forks", {
      name:        cc.name,
      plan_id:     cc.plan,
      storage:     cc.storage,
      provider_id: cc.platform,
      target_time: cc.at.try(&.to_rfc3339),
      region_id:   cc.region,
      is_ha:       cc.ha,
      network_id:  cc.network,
    }
    Cluster.from_json resp.body
  end

  # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridupgrade/upgrade-cluster
  def upgrade_cluster(uc)
    resp = post "clusters/#{uc.cluster_id}/upgrade", {
      is_ha:               uc.ha,
      plan_id:             uc.plan,
      postgres_version_id: uc.postgres_version,
      storage:             uc.storage,
    }
    Array(Operation).from_json resp.body, root: "operations"
  end

  # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridupgrade/get-upgrade-status
  def upgrade_cluster_status(id)
    resp = get "clusters/#{id}/upgrade"
    Array(Operation).from_json resp.body, root: "operations"
  end

  def upgrade_cluster_cancel(id)
    delete "clusters/#{id}/upgrade"
  end

  # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusterid/update-cluster
  def update_cluster(cluster_id, body)
    resp = patch "clusters/#{cluster_id}", body
    ClusterDetail.from_json resp.body
  end

  def replicate_cluster(cc)
    resp = post "clusters/#{cc.replica}/replicas", {
      name:        cc.name,
      plan_id:     cc.plan,
      provider_id: cc.platform,
      region_id:   cc.region,
    }
    Cluster.from_json resp.body
  end

  def destroy_cluster(id)
    delete "clusters/#{id}"
  end

  # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridrestart/restart-cluster
  def restart_cluster(id, service : String)
    put "clusters/#{id}/restart", {service: service}
  end

  #
  # Providers
  #

  jrecord Plan, id : String, display_name : String

  jrecord Region, id : String, display_name : String, location : String

  jrecord Provider, id : String,
    display_name : String,
    regions : Array(Region),
    plans : Array(Plan)

  # List available providers.
  #
  # https://crunchybridgeapi.docs.apiary.io/#reference/0/providers/list-providers
  def get_providers
    resp = get "providers"
    Array(Provider).from_json resp.body, root: "providers"
  end

  #
  # Firewall Rules
  #

  jrecord FirewallRule, id : String, rule : String

  # Add a firewall rule to a cluster.
  #
  # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridfirewall/create-firewall-rule
  def add_firewall_rule(cluster_id, cidr)
    post "clusters/#{cluster_id}/firewall", {rule: cidr}
  end

  # Remove a firewall rule from a cluster.
  #
  # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridfirewallruleid/destroy-firewall-rule
  def delete_firewall_rule(cluster_id, firewall_rule_id)
    delete "clusters/#{cluster_id}/firewall/#{firewall_rule_id}"
  end

  # List current firewall rules for a cluster.
  #
  # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridfirewall/list-firewall-rules
  def get_firewall_rules(cluster_id)
    resp = get "clusters/#{cluster_id}/firewall"
    Array(FirewallRule).from_json resp.body, root: "firewall_rules"
  end

  #
  # Log Destinations
  #

  jrecord LogDestination,
    id : String,
    host : String,
    port : Int32,
    template : String,
    description : String

  # List existing loggers for a cluster.
  #
  # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridloggers/list-loggers
  def get_log_destinations(cluster_id)
    resp = get "clusters/#{cluster_id}/loggers"
    Array(LogDestination).from_json resp.body, root: "loggers"
  end

  # Add a logger to a cluster.
  #
  # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridloggers/create-logger
  def add_log_destination(cluster_id, ld)
    resp = post "clusters/#{cluster_id}/loggers", ld
    resp.body
  end

  # Remove a logger from a cluster.
  #
  # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridloggersloggerid/destroy-logger
  def destroy_log_destination(cluster_id, logdest_id)
    resp = delete "clusters/#{cluster_id}/loggers/#{logdest_id}"
    resp.body
  end

  #
  # Cluster Roles
  #

  jrecord Role,
    account_id : String? = nil,
    account_email : String? = nil,
    name : String = "",
    password : String? = nil,
    uri : URI? = nil

  # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridroles/create-role
  def create_role(cluster_id)
    resp = post "clusters/#{cluster_id}/roles", "{}"
    Role.from_json resp.body
  end

  # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridrolesrolename/get-role
  def get_role(cluster_id : Identifier, role_name : String)
    return get_role(cluster_id.to_s, role_name) if cluster_id.eid?
    c = get_cluster_by_name(cluster_id)
    get_role(c.id, role_name)
  end

  def get_role(cluster_id, role_name)
    resp = get "clusters/#{cluster_id}/roles/#{role_name}"
    Role.from_json resp.body
  end

  # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridroles/list-roles
  def list_roles(cluster_id)
    resp = get "clusters/#{cluster_id}/roles"
    Array(Role).from_json resp.body, root: "roles"
  end

  # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridrolesrolename/update-role
  def update_role(cluster_id, role_name, ur)
    resp = put "clusters/#{cluster_id}/roles/#{role_name}", ur
    Role.from_json resp.body
  end

  # https://crunchybridgeapi.docs.apiary.io/#reference/0/clustersclusteridrolesrolename/delete-role
  def delete_role(cluster_id, role_name)
    resp = delete "clusters/#{cluster_id}/roles/#{role_name}"
    Role.from_json resp.body
  end

  def get_tempkey(cluster_id)
    resp = post "clusters/#{cluster_id}/tempkeys"
    Tempkey.from_json resp.body
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
