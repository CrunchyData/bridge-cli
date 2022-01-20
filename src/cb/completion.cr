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
      when "info", "destroy", "uri"
        return info
      when "create"
        return create
      when "firewall"
        return firewall
      when "logdest"
        return logdest
      when "psql"
        return psql
      when "teamcert"
        return teams
      when "scope"
        return scope
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
      "version\tShow version information",
      "login\tStore API key",
      "token\tGet current API token",
      "list\tList clusters",
      "teams\tList teams",
      "teamcert\tGet team public cert",
      "info\tDetailed cluster info",
      "uri\tConnection uri",
      "create\tProvision a new cluster",
      "destroy\tDestroy a cluster",
      "firewall\tManage firewall rules",
      "psql\tInteractive psql console",
      "logdest\tManage log destinations",
      "scope\tRun diagnostic queries",
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

    if args.includes? "--network"
      return [] of String
    end

    if last_arg? "-n", "--name"
      return [] of String
    end

    if last_arg? "--at"
      return [] of String
    end

    if last_arg? "-v", "--version"
      return [] of String
    end

    cluster_suggest("--fork").tap { |s| return s if s }
    cluster_suggest("--replica").tap { |s| return s if s }
    platform_region_plan_suggest.tap { |s| return s if s }
    storage_suggest.tap { |s| return s if s }

    if last_arg? "--team", "-t"
      return teams
    end

    if last_arg? "--ha"
      return ["false", "true"]
    end

    # return missing args
    suggest = [] of String
    suggest << "--fork\tcluster to fork" unless has_full_flag?(:fork) || has_full_flag?(:replica)
    suggest << "--replica\tcluster create read-reaplica from" unless has_full_flag?(:fork) || has_full_flag?(:replica)
    suggest << "--at\tPITR time in RFC3339" if has_full_flag?(:fork) && !has_full_flag?(:at)
    suggest << "--help\tshow help" if args.size == 2
    suggest << "--platform\tcloud provider" unless has_full_flag? :platform
    suggest << "--team\tcrunchy bridge team" unless has_full_flag?(:team) || has_full_flag?(:fork) || has_full_flag?(:replica)
    suggest << "--storage\tstorage size in GiB" unless has_full_flag?(:storage) || has_full_flag?(:replica)
    suggest << "--ha\thigh availability" unless has_full_flag?(:ha) || has_full_flag?(:replica)
    suggest << "--name\tcluster name" unless has_full_flag? :name
    suggest << "--network\tnetwork id" unless has_full_flag? :network
    suggest << "--version\tmajor version" unless has_full_flag?(:version) || has_full_flag?(:fork) || has_full_flag?(:replica)
    return suggest
  end

  private def platform_region_plan_suggest
    if last_arg? "-p", "--platform"
      return ["aws\tAmazon Web Services", "gcp\tGoogle Cloud Platform", "azr\tMicrosoft Azure"]
    end

    if last_arg? "aws", "gcp", "azr"
      return ["--region", "--plan"]
    end

    platform = find_arg_value "--platform", "-p"
    platform = "azure" if platform == "azr"

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
  end

  private def storage_suggest
    if last_arg? "--storage", "-s"
      return [100, 256, 512, 1024].map { |s| "#{s}\t#{s} GiB" }
    end
  end

  private def cluster_suggest(flag = "--cluster")
    if last_arg?(flag)
      cluster_suggestions
    end
  end

  def firewall
    cluster = find_arg_value "--cluster"

    cluster_suggest.tap { |suggest| return suggest if suggest }

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

  def logdest
    case @args[1]
    when "list"
      logdest_list
    when "destroy"
      logdest_destroy
    when "add"
      logdest_add
    else
      [
        "list\tlist all log destinations for a cluster",
        "add\tadd a new log destination to a cluster",
        "destroy\tremove a new destination from a cluster",
      ]
    end
  end

  def logdest_list
    return ["--cluster\tcluster id"] if @args.size == 3

    cluster = find_arg_value "--cluster"

    if last_arg?("--cluster")
      return cluster.nil? ? cluster_suggestions : [] of String
    end

    [] of String
  end

  def logdest_destroy
    return ["--cluster\tcluster id"] if @args.size == 3

    cluster = find_arg_value "--cluster"
    logdest = find_arg_value "--logdest"

    if last_arg?("--cluster")
      return cluster.nil? ? cluster_suggestions : [] of String
    end

    if last_arg?("--logdest")
      return [] of String unless logdest.nil? && cluster
      return client.get_logdests(cluster).map { |d| "#{d.id}\t#{d.description}" }
    end

    if cluster && !logdest
      ["--logdest\tlog destination id"]
    else
      [] of String
    end
  end

  def logdest_add
    if last_arg?("--cluster")
      return cluster_suggestions
    end

    # return missing args
    suggest = [] of String
    suggest << "--help\tshow help" if args.size == 3
    suggest << "--cluster\tcluster id" unless has_full_flag? :cluster
    suggest << "--host\thostname" unless has_full_flag? :host
    suggest << "--port\tport number" unless has_full_flag? :port
    suggest << "--desc\tdescription" unless has_full_flag? :desc
    suggest << "--template\ttemplate" unless has_full_flag? :template
    return suggest
  end

  def psql
    return cluster_suggestions if @args.size == 2

    if last_arg?("--database")
      [] of String
    end

    suggest = [] of String
    suggest << "--database\tName of database" unless has_full_flag? :database
    return suggest
  end

  def scope
    return ["--cluster\tcluster id"] if @args.size == 2

    if last_arg?("--cluster")
      return cluster_suggestions
    end

    if last_arg?("--suite")
      return ["all\tRun all scopes", "quick\tRun some scopes"]
    end

    if last_arg?("--database")
      [] of String
    end

    suggest = ::Scope::Check.all.reject { |c| @args.includes? c.flag }.map { |c| "#{c.flag}\t#{c.desc}" }
    suggest << "--suite\tRun predefined scopes" unless @args.includes? "--suite"
    suggest << "--database\tName of database" unless @args.includes? "--database"

    return suggest
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
    full << :port if has_full_flag? "--port"
    full << :desc if has_full_flag? "--desc"
    full << :template if has_full_flag? "--template"
    full << :host if has_full_flag? "--host"
    full << :fork if has_full_flag? "--fork"
    full << :replica if has_full_flag? "--replica"
    full << :network if has_full_flag? "--network"
    full << :version if has_full_flag? "--version", "-v"
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
