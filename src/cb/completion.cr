class CB::Completion
  class NoClientError < RuntimeError
  end

  def self.parse(client, commandline)
    new(client, commandline).parse
  end

  getter commandline : String
  getter args : Array(String)
  getter full_flags : Set(Symbol)

  def initialize(@client : Client?, @commandline : String)
    @args = @commandline.split(/\s+/)[1..-1]
    @full_flags = find_full_flags
  end

  def client : Client
    c = @client
    raise NoClientError.new unless c
    c
  end

  def parse : Array(String)
    result = _parse
    # File.open("completion.log", "a") do |f|
    #  f.puts @args.inspect
    #  f.puts result.inspect
    #  f.puts
    # end
    result
  end

  def _parse : Array(String)
    if args.size < 2
      return top_level
    else
      case args.first
      when "info"
        return info
      when "psql"
        return info
      when "destroy"
        return info
      when "create"
        return create
      when "firewall"
        return firewall
      else
        [] of String
      end
    end
  rescue NoClientError
    [] of String
  end

  def top_level
    options = [
      "--help\tShow help and usage",
      "--version\tShow version information",
      "login\tStore API key",
      "token\tGet current API token",
      "list\tList clusters",
      "teams\tList teams",
      "info\tDetailed cluster info",
      "create\tProvision a new cluster",
      "destroy\tDestroy a cluster",
      "firewall\tManage firewall rules",
      "psql\tInteractive psql console",
    ]
    if @client
      options
    else
      options.first 3
    end
  end

  def info
    cluster_suggestions
  end

  def cluster_suggestions
    teams = client.get_teams
    client.get_clusters.map do |c|
      team_name = teams.find { |t| t.id == c.team_id }.try(&.name) || "unknown_team"
      "#{c.id}\t#{team_name}/#{c.name}"
    end
  end

  def teams
    client.get_teams.map { |t| "#{t.id}\t#{t.name}" }
  end

  def create
    if args.includes? "--help"
      return [] of String
    end

    if last_arg? "-p", "--platform"
      return ["aws\tAmazon Web Services", "gcp\tGoogle Cloud Platform", "azr\tMicrosoft Azure"]
    end

    if last_arg? "-n", "--name"
      return [] of String
    end

    if last_arg? "aws", "gcp", "azr"
      return ["--region", "--plan"]
    end

    platform = find_arg_value "--platform", "-p"

    if last_arg? "-r", "--region"
      return platform ? region(platform) : [] of String
    end

    if last_arg? "--plan"
      return platform ? plan(platform) : [] of String
    end

    if has_full_flag? :platform
      if has_full_flag?(:region) && !has_full_flag?(:plan)
        return ["--plan"]
      elsif !has_full_flag?(:region) && has_full_flag?(:plan)
        return ["--region"]
      end
    end

    if last_arg? "--storage", "-s"
      return [100, 256, 512, 1024].map { |s| "#{s}\t#{s} GiB" }
    end

    if last_arg? "--team", "-t"
      return teams
    end

    if last_arg? "--ha"
      return ["false", "true"]
    end

    # return missing args
    suggest = [] of String
    suggest << "--help\tshow help" if args.size == 2
    suggest << "--platform\tcloud provider" unless has_full_flag? :platform
    suggest << "--team\tcrunchy bridge team" unless has_full_flag? :team
    suggest << "--storage\tstorage size in GiB" unless has_full_flag? :storage
    suggest << "--ha\thigh availability" unless has_full_flag? :ha
    suggest << "--name\tcluster name" unless has_full_flag? :name
    return suggest
  end

  def firewall
    cluster = find_arg_value "--cluster"

    if last_arg?("--cluster")
      return cluster.nil? ? cluster_suggestions : [] of String
    end

    if last_arg?("--add")
      return [] of String
    end

    if last_arg?("--remove")
      if cluster
        return firewall_rules(cluster)
      else
        return [] of String
      end
    end

    if has_full_flag? :cluster
      suggestions = ["--add\tcidr of rule to add"]
      suggestions << "--remove\tcidr of rule to remove" unless firewall_rules(cluster).empty?
      return suggestions
    else
      return ["--cluster\tcluster id"]
    end
  end

  def firewall_rules(cluster_id)
    rules = client.get_firewall_rules(cluster_id)
    rules.map { |r| r.rule } - @args
  rescue Client::Error
    [] of String
  end

  def find_arg_value(arg1 : String, arg2 : String? = nil) : String?
    idx = @args.index(arg1)
    idx = @args.index(arg2) if idx.nil? && arg2
    value = idx ? @args[idx + 1] : nil
    value = nil if value == ""
    value
  rescue IndexError
    nil
  end

  def region(platform)
    platform = client.get_providers.find { |p| p.id == platform }
    return [] of String unless platform
    platform.regions.map { |r| "#{r.id}\t#{r.display_name} [#{r.location}]" }
  end

  def plan(platform)
    platform = client.get_providers.find { |p| p.id == platform }
    return [] of String unless platform
    platform.plans.map { |r| "#{r.id}\t#{r.display_name}" }
  end

  # only return the long version, but search for long and short
  def find_full_flags
    full = Set(Symbol).new
    full << :ha if has_full_flag? "--ha"
    full << :plan if has_full_flag? "--plan"
    full << :name if has_full_flag? "--name", "-n"
    full << :team if has_full_flag? "--team", "-t"
    full << :region if has_full_flag? "--region", "-r"
    full << :cluster if has_full_flag? "--cluster"
    full << :storage if has_full_flag? "--storage", "-s"
    full << :platform if has_full_flag? "--platform", "-p"
    return full
  end

  def has_full_flag?(arg1 : String, arg2 : String? = nil) : Bool
    idx = @args.index(arg1) || @args.index(arg2)
    return false unless idx
    return !@args[idx + 1]?.nil?
  end

  def has_full_flag?(*names : Symbol) : Bool
    names.all? { |n| @full_flags.includes? n }
  end

  def last_arg?(*args) : Bool
    last = @args[-2]
    args.includes? last
  end
end
