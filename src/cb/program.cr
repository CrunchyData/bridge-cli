require "./creds"
require "./token"

class CB::Program
  class Error < Exception
    property show_usage : Bool = false
  end

  property input : IO
  property output : IO
  property host : String
  property creds : CB::Creds?
  property token : CB::Token?

  def initialize(host = nil, @input = STDIN, @output = STDOUT)
    @host = host || "api.crunchybridge.com"
    Colorize.enabled = false unless output == STDOUT && input == STDIN
  end

  def login
    raise Error.new "No valid credentials found. Please login." unless output.tty?
    hint = "from https://www.crunchybridge.com/settings/ " if host == "api.crunchybridge.com"
    output.puts "add credentials for #{host.colorize.t_name} #{hint}>"
    output.print "  application ID: "
    id = input.gets
    if id.nil? || id.empty?
      STDERR.puts "#{"error".colorize.red.bold}: applicaton ID must be present"
      exit 1
    end

    print "  application secret: "
    secret = input.noecho { input.gets }
    output.print "\n"
    if secret.nil? || secret.empty?
      STDERR.puts "#{"error".colorize.red.bold}: applicatoin secret must be present"
      exit 1
    end

    Creds.new(host, id, secret).store
  end

  def creds : CB::Creds
    if c = @creds
      return c
    end
    @cred = Creds.for_host(host) || login
  end

  def token : CB::Token
    if t = @token
      return t
    end
    t = Token.for_host(host) || get_token
    @token = t
  end

  private def get_token
    Client.get_token(creds)
  rescue e : Client::Error
    if e.unauthorized?
      STDERR << "error".colorize.t_warn << ": Credentials invalid. Please login again.\n"
      creds.delete
      exit 1
    end
    raise e
  end

  # api may lose the token before it's actually expired
  # returns false if the token didn't need to be refreshed
  #         true if refreshing the token worked and the user should retry
  # it is assumed that the token will work after a refresh
  def ensure_token_still_good : Bool
    return false if test_token # token already works
    @token = get_token
    return true if test_token # token was fixed after refresh

    STDERR << "error".colorize.t_warn << ": Could not refresh token. Please login again.\n"
    exit 1
  end

  private def test_token
    token_works = false
    begin
      client.get_teams
      token_works = true
    rescue Client::Error
    end
    token_works
  end

  def client
    Client.new token
  end

  def teams
    teams = client.get_teams
    name_max = teams.map(&.name.size).max? || 0
    teams.each do |team|
      output << team.id.colorize.t_id
      output << "\t"
      output << team.name.ljust(name_max).colorize.t_name
      output << "\t"
      output << team.human_roles.join ", "
      output << "\n"
    end
  end

  def list_clusters
    clusters = client.get_clusters
    teams = client.get_teams
    cluster_max = clusters.map(&.name.size).max? || 0

    clusters.each do |cluster|
      output << cluster.id.colorize.t_id
      output << "\t"
      output << cluster.name.ljust(cluster_max).colorize.t_name
      output << "\t"
      team_name = teams.find { |t| t.id == cluster.team_id }.try &.name || cluster.team_id
      output << team_name.colorize.t_alt
      output << "\n"
    end
  end

  def destroy_cluster(id)
    c = client.get_cluster id
    output << "About to " << "delete".colorize.t_warn << " cluster " << c.name.colorize.t_name
    team_name = team_name_for_cluster c
    output << " from team #{team_name}" if team_name
    output << ".\n  Type the cluster's name to confirm: "
    response = input.gets
    if c.name == response
      client.destroy_cluster id
      output.puts "Cluster #{c.id.colorize.t_id} destroyed"
    else
      output.puts "Reponse did not match, did not destroy the cluster"
    end
  end

  def info(id)
    c = client.get_cluster id
    print_team_slash_cluster c, output

    details = {
      "state"    => c.state,
      "created"  => c.created_at.to_rfc3339,
      "plan"     => "#{c.plan_id} (#{c.memory}GiB ram, #{c.cpu}vCPU)",
      "storage"  => "#{c.storage}GiB",
      "ha"       => (c.is_ha ? "on" : "off"),
      "platform" => c.provider_id,
      "region"   => c.region_id,
    }
    pad = 10
    details.each do |k, v|
      output << k.rjust(pad).colorize.bold << ": "
      output << v << "\n"
    end

    firewall_rules = client.get_firewall_rules id
    output << "firewall".rjust(pad).colorize.bold << ": "
    if firewall_rules.empty?
      output << "no rules\n"
    else
      output << "allowed cidrs".colorize.underline << "\n"
    end
    firewall_rules.each { |fr| output << " "*(pad + 4) << fr.rule << "\n" }
  end

  def team_cert(team_id)
    cert = client.get("teams/#{team_id}.pem").body
    output.puts cert
  rescue e : Client::Error
    if e.not_found?
      STDERR << "error".colorize.t_warn << ": No public cert found.\n"
    else
      raise e
    end
  end

  private def print_team_slash_cluster(c, io : IO)
    team_name = team_name_for_cluster c
    io << team_name << "/" if team_name
    io << c.name.colorize.t_name << "\n"
    team_name
  end

  private def team_name_for_cluster(c)
    # no way to look up a single team yet
    client.get_teams.find { |t| t.id == c.team_id }.try &.name.colorize.t_alt
  end
end
