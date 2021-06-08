class IO
  # no-op for non-file descriptor IOs, e.g. specs
  def noecho
    yield
  end
end

class CB::Program
  class Error < Exception
    property show_usage : Bool = false
  end

  property input : IO
  property output : IO
  property host : String
  property creds : CB::Creds?
  property token : CB::Token?

  def initialize(@host = "api.crunchybridge.com", @input = STDIN, @output = STDOUT)
    Colorize.enabled = false unless output == STDOUT && input == STDIN
  end

  def login
    output.puts "add credentials for #{host} >"
    output.print "  application ID: "
    id = input.gets
    raise Error.new "applicaton ID must be present" if id.nil? || id.empty?

    print "  application secret: "
    secret = input.noecho { input.gets }
    raise Error.new "applicatoin secret must be present" if secret.nil? || secret.empty?
    output.print "\n"

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
    t = Token.for_host(host) || Client.get_token(creds)
    @token = t
  end

  def client
    Client.new token
  end

  def teams
    teams = client.get_teams
    name_max = teams.map(&.name.size).max
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
    cluster_max = clusters.map(&.name.size).max

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
    team_name = team_name_for_cluster c
    output << team_name << "/" if team_name
    output << c.name.colorize.t_name << "\n"

    details = {
      "state"    => c.state,
      "created"  => c.created_at,
      "memory"   => "#{c.memory}GiB",
      "cpu"      => c.cpu,
      "storage"  => "#{c.storage}GiB",
      "ha"       => (c.is_ha ? "on" : "off"),
      "platform" => c.provider_id,
      "regoin"   => c.region_id,
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

  private def team_name_for_cluster(c)
    # no way to look up a single team yet
    client.get_teams.find { |t| t.id == c.team_id }.try &.name.colorize.t_alt
  end
end
