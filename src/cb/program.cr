class IO
  # no-op for non-file descriptor IOs, e.g. specs
  def noecho
    yield
  end
end

require "colorize"

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
    if output == STDOUT && input == STDIN
      Colorize.on_tty_only!
    else
      Colorize.enabled = false
    end
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
      output << team.id.colorize.light_cyan
      output << "\t"
      output << team.name.ljust(name_max).colorize.cyan
      output << "\t"
      output << team.human_roles.join ", "
      output << "\n"
    end
  end

  def clusters
    clusters = client.get_clusters
    teams = client.get_teams
    cluster_max = clusters.map(&.name.size).max

    clusters.each do |cluster|
      output << cluster.id.colorize.light_cyan
      output << "\t"
      output << cluster.name.ljust(cluster_max).colorize.cyan
      output << "\t"
      team_name = teams.find { |t| t.id == cluster.team_id }.try &.name || cluster.team_id
      output << team_name
      output << "\n"
    end
  end

  def destroy_cluster(id)
    c = client.get_cluster id
    team_name = client.get_teams.find { |t| t.id == c.team_id }.try &.name.colorize.green
    output << "About to " << "delete".colorize.red << " cluster " << c.name.colorize.cyan
    output << " from team #{team_name}" if team_name
    output << ".\n  Type the cluster's name to confirm: "
    response = input.gets
    if c.name == response
      client.destroy_cluster id
      output.puts "Cluster #{c.id.colorize.light_cyan} destroyed"
    else
      output.puts "Reponse did not match, did not destroy the cluster"
    end
  end

  def info(id)
    pp client.get_cluster id
  end
end
