class CB::Completion
  class NoClientError < RuntimeError
  end

  def self.parse(client, commandline)
    new(client, commandline).parse
  end

  getter commandline : String
  getter args : Array(String)
  getter full_flags : Set(Symbol)

  macro suggest_none
    return [] of String
  end

  macro suggest_bool
    return ["false", "true"]
  end

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
      top_level
    else
      case args.first
      when "info", "destroy", "rename", "logs", "suspend", "resume"
        single_cluster_suggestion
      when "create"
        create
      when "detach"
        detach
      when "firewall"
        firewall
      when "logdest"
        logdest
      when "maintenance"
        maintenance
      when "network"
        network
      when "psql"
        psql
      when "restart"
        restart
      when "role"
        role
      when "team"
        team
      when "team-member"
        team_member
      when "teamcert"
        teams
      when "tailscale"
        tailscale
      when "upgrade"
        upgrade
      when "uri"
        uri
      when "scope"
        scope
      when "backup"
        backup
      else
        [] of String
      end
    end
  rescue NoClientError
    suggest_none
  end

  def top_level
    options = [
      "--help\tShow help and usage",
      "version\tShow version information",
      "login\tStore API key",
      "logout\tRemove stored API key and token",
      "token\tGet current API token",
      "list\tList clusters",
      "team\tManage teams",
      "team-member\tManage a team's members",
      "teamcert\tGet team public cert",
      "tailscale\tManage tailscale",
      "maintenance\tManage cluster maintenance",
      "network\tManage networks",
      "info\tDetailed cluster info",
      "uri\tConnection uri",
      "create\tProvision a new cluster",
      "destroy\tDestroy a cluster",
      "rename\tRename a cluster",
      "detach\tDetach a cluster",
      "restart\tRestart a cluster",
      "firewall\tManage firewall rules",
      "backup\tManage backups",
      "psql\tInteractive psql console",
      "logdest\tManage log destinations",
      "scope\tRun diagnostic queries",
      "logs\tView live cluster logs",
      "suspend\tTemporarily turn off a cluster",
      "resume\tTurn on a suspended cluster",
    ]
    if @client
      options
    else
      options.first 4
    end
  end

  def single_cluster_suggestion
    return cluster_suggestions if args.size == 2
    suggest_none
  end

  def team_suggestions
    teams = client.get_teams
    teams.map { |t| "#{t.id}\t#{t.name}" }
  end

  def cluster_suggestions
    teams = client.get_teams
    clusters = client.get_clusters(teams)

    clusters.map do |c|
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
    suggest
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
      suggestions
    else
      ["--cluster\tcluster id"]
    end
  end

  def firewall_rules(cluster_id)
    rules = client.get_firewall_rules(cluster_id)
    rules.map(&.rule) - @args
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

  def tailscale
    case @args[1]
    when "connect"
      tailscale_connect
    when "disconnect"
      tailscale_disconnect
    else
      [
        "connect\tadd a cluster to tailscale",
        "disconnect\tremove a cluster from tailscale",
      ]
    end
  end

  def tailscale_connect : Array(String)
    cluster = find_arg_value "--cluster"

    if last_arg?("--cluster")
      return cluster.nil? ? cluster_suggestions : [] of String
    end

    if last_arg?("--authkey")
      suggest_none
    end

    suggest = [] of String
    suggest << "--cluster\tcluster id" unless has_full_flag? :cluster
    suggest << "--authkey\tapreuthorization key" unless has_full_flag? :authkey
    suggest
  end

  def tailscale_disconnect : Array(String)
    return ["--cluster\tcluster id"] if @args.size == 3

    cluster = find_arg_value "--cluster"

    if last_arg?("--cluster")
      return cluster.nil? ? cluster_suggestions : [] of String
    end

    suggest_none
  end

  def maintenance
    case @args[1]
    when "info"
      upgrade_status
    when "set"
      maintenance_window_update
    when "cancel"
      upgrade_cancel
    else
      [
        "info\tdisplay cluster maintenance information",
        "set\tupdate the cluster default maintenance window",
        "cancel\tcancel a cluster maintenance",
      ]
    end
  end

  def maintenance_window_update : Array(String)
    cluster = find_arg_value "--cluster"

    if last_arg?("--cluster")
      return cluster.nil? ? cluster_suggestions : [] of String
    end

    if last_arg?("--window-start", "--unset")
      suggest_none
    end

    suggest = [] of String
    suggest << "--cluster\tcluster id" unless has_full_flag? :cluster
    suggest << "--window-start\tmaintenance window start (UTC)" unless has_full_flag?(:unset) || has_full_flag?(:window_start)
    suggest << "--unset\tUnset mainetnance window" unless has_full_flag?(:unset) || has_full_flag?(:window_start)
    suggest
  end

  def network
    case @args[1]
    when "info"
      network_info
    when "list"
      network_list
    else
      [
        "info\ndetailed network information",
        "list\tlist available networks",
      ]
    end
  end

  def network_info
    if last_arg?("--format")
      return ["table", "json"]
    end

    if last_arg?("--network")
      return [] of String
    end

    suggest = [] of String
    suggest << "--format\tchoose output format" unless has_full_flag? :format
    suggest << "--network\tnetwork id" unless has_full_flag? :network
    suggest
  end

  def network_list
    if last_arg?("--format")
      return ["table", "json"]
    end

    if last_arg?("--team")
      return team_suggestions
    end

    suggest = [] of String
    suggest << "--format\tchoose output format" unless has_full_flag? :format
    suggest << "--team\tchoose team" unless has_full_flag? :team
    suggest
  end

  def role
    case @args[1]
    when "create"
      role_create
    when "destroy"
      role_destroy
    when "list"
      role_list
    when "update"
      role_update
    else
      [
        "create\tcreate a role for a cluster",
        "destroy\tremove a role from a cluster",
        "list\tlist roles for a cluster",
        "update\tupdate a role for a cluster",
      ]
    end
  end

  def role_create
    return ["--cluster\tcluster id"] if @args.size == 3

    cluster = find_arg_value "--cluster"

    if last_arg?("--cluster")
      return cluster.nil? ? cluster_suggestions : [] of String
    end

    [] of String
  end

  def role_destroy
    return ["--cluster\tcluster id"] if args.size == 3

    cluster = find_arg_value "--cluster"

    if last_arg?("--cluster")
      return cluster.nil? ? cluster_suggestions : [] of String
    end

    if last_arg? "--name"
      return Role::VALID_CLUSTER_ROLES.to_a
    end

    suggest = [] of String
    suggest << "--name\trole name" unless has_full_flag? :name
    suggest
  end

  def role_list
    return ["--cluster\tcluster id"] if args.size == 3

    cluster = find_arg_value "--cluster"

    if last_arg?("--cluster")
      return cluster.nil? ? cluster_suggestions : [] of String
    end

    if last_arg?("--format")
      return ["table", "json"]
    end

    suggest = [] of String
    suggest << "--format\toutput format" unless has_full_flag? :format
    suggest << "--no-header\tomit table header" unless has_full_flag? :no_header
    suggest
  end

  def role_update
    return ["--cluster\tcluster id"] if args.size == 3

    cluster = find_arg_value "--cluster"

    if last_arg?("--cluster")
      return cluster.nil? ? cluster_suggestions : [] of String
    end

    if last_arg? "--name"
      return Role::VALID_CLUSTER_ROLES.to_a
    end

    if last_arg?("--read-only")
      return ["false", "true"]
    end

    if last_arg?("--rotate-password")
      return ["false", "true"]
    end

    suggest = [] of String
    suggest << "--name\trole name" unless has_full_flag? :name
    suggest << "--rotate-password" unless has_full_flag? :rotate_password
    suggest << "--read-only" unless has_full_flag? :read_only
    suggest
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
      return client.get_log_destinations(cluster).map { |d| "#{d.id}\t#{d.description}" }
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
    suggest
  end

  def psql
    return cluster_suggestions if @args.size == 2

    if last_arg?("--database")
      return [] of String
    end

    if last_arg?("--role")
      return Role::VALID_CLUSTER_ROLES.to_a
    end

    suggest = [] of String
    suggest << "--database\tName of database" unless has_full_flag? :database
    suggest << "--role\trole name" unless has_full_flag? :role
    suggest
  end

  def restart
    return cluster_suggestions if @args.size == 2

    suggest = [] of String
    suggest << "--confirm\tconfirm cluster #{@args.first}" unless has_full_flag? :confirm
    suggest << "--full\tfull server restart" unless has_full_flag? :full
    suggest
  end

  def detach
    return cluster_suggestions if @args.size == 2

    suggest = [] of String
    suggest << "--confirm\tconfirm cluster #{@args.first}" unless has_full_flag? :confirm
    suggest
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

    suggest
  end

  #
  # Backup Completion.
  #

  def backup
    case @args[1]
    when ""
      return [
        "list\tlist backups",
        "capture\tstart a new backup",
        "token\tcreate a backup token",
      ]
    when "list", "capture"
      return cluster_suggestions if @args.size == 3
    when "token"
      return cluster_suggestions if @args.size == 3
      return backup_token
    end

    suggest_none
  end

  def backup_token
    if last_arg?("--format")
      return ["default", "pgbackrest"]
    end

    suggest = [] of String
    suggest << "--format\toutput format" unless has_full_flag? :format
    suggest
  end

  #
  # Team Completion.
  #

  def team
    case @args[1]
    when "create"
      team_create
    when "info"
      team_info
    when "list"
      team_list
    when "update"
      team_update
    when "destroy"
      team_destroy
    else
      [
        "create\tcreate a new team",
        "list\tlist available teams",
        "info\tshow details of a team",
        "update\tupdate a team",
        "destroy\tdelete a team",
      ]
    end
  end

  def team_create
    if last_arg? "--name"
      suggest_none
    end

    suggest = [] of String
    suggest << "--name\tteam name" unless has_full_flag? :name
    suggest
  end

  def team_list
    suggest_none
  end

  def team_info
    return teams if @args.size == 3
    suggest_none
  end

  def team_update
    return teams if @args.size == 3

    if last_arg? "--billing-email"
      suggest_none
    end

    if last_arg? "--enforce-sso"
      suggest_bool
    end

    if last_arg? "--name"
      suggest_none
    end

    suggest = [] of String
    suggest << "--billing-email\tteams billing email address" unless has_full_flag? :billing_email
    suggest << "--enforce-sso\tenforce SSO access to team" unless has_full_flag? :enforce_sso
    suggest << "--help\tshow help" unless has_full_flag? :help
    suggest << "--name\tteam name" unless has_full_flag? :name
    suggest
  end

  def team_destroy
    return teams if @args.size == 3
    suggest_none
  end

  #
  # Team Member Completion
  #

  def team_member
    case @args[1]
    when "add"
      team_member_add
    when "info"
      team_member_info
    when "list"
      team_member_list
    when "update"
      team_member_update
    when "remove"
      team_member_remove
    else
      [
        "add\tadd a team member",
        "list\tlist current team members",
        "info\tshow details of a team member",
        "update\tupdate a team member",
        "remove\tremove a team member",
      ]
    end
  end

  def team_member_add
    if last_arg?("--team")
      return teams
    end

    if last_arg? "--email"
      suggest_none
    end

    if last_arg?("--role")
      return ["admin", "manager", "member"]
    end

    suggest = [] of String
    suggest << "--team\tteam ID" unless has_full_flag? :team
    suggest << "--email\tuser's email address" unless has_full_flag? :email
    suggest << "--role\tteam member role" unless has_full_flag? :role
    suggest
  end

  def team_member_info
    if last_arg?("--team")
      return teams
    end

    if last_arg? "--account", "--email"
      suggest_none
    end

    suggest = [] of String
    suggest << "--team\tteam ID" unless has_full_flag? :team
    suggest << "--account\tuser's account ID" unless has_full_flag?(:account) || has_full_flag?(:email)
    suggest << "--email\tuser's email address" unless has_full_flag?(:email) || has_full_flag?(:account)
    suggest
  end

  def team_member_list
    if last_arg?("--team")
      return teams
    end

    suggest = [] of String
    suggest << "--team\tteam ID" unless has_full_flag? :team
    suggest
  end

  def team_member_update
    if last_arg?("--team")
      return teams
    end

    if last_arg? "--account", "--email"
      suggest_none
    end

    if last_arg?("--role")
      return ["admin", "manager", "member"]
    end

    suggest = [] of String
    suggest << "--team\tteam ID" unless has_full_flag? :team
    suggest << "--account\tuser's account ID" unless has_full_flag?(:account) || has_full_flag?(:email)
    suggest << "--email\tuser's email address" unless has_full_flag?(:email) || has_full_flag?(:account)
    suggest << "--role\tteam member role" unless has_full_flag? :role
    suggest
  end

  def team_member_remove
    if last_arg?("--team")
      return teams
    end

    if last_arg?("--account") || last_arg?("--email")
      suggest_none
    end

    suggest = [] of String
    suggest << "--team\tteam ID" unless has_full_flag? :team
    suggest << "--account\tuser's account ID" unless has_full_flag?(:account) || has_full_flag?(:email)
    suggest << "--email\tuser's email address" unless has_full_flag?(:email) || has_full_flag?(:account)
    suggest
  end

  def upgrade
    case @args[1]
    when "cancel"
      upgrade_cancel
    when "status"
      upgrade_status
    when "start"
      upgrade_start
    else
      [
        "start\tstart cluster upgrade",
        "cancel\tcancel cluster upgrade",
        "status\tshow status of cluster upgrade",
      ]
    end
  end

  def upgrade_cancel
    return ["--cluster\tcluster id"] if @args.size == 3

    cluster = find_arg_value "--cluster"

    if last_arg? "--cluster"
      return cluster.nil? ? cluster_suggestions : [] of String
    end

    [] of String
  end

  def upgrade_status
    return ["--cluster\tcluster id"] if @args.size == 3

    cluster = find_arg_value "--cluster"

    if last_arg? "--cluster"
      return cluster.nil? ? cluster_suggestions : [] of String
    end

    [] of String
  end

  def upgrade_start
    if last_arg? "--cluster"
      return cluster_suggestions
    end

    if last_arg? "--plan"
      cluster_id = find_arg_value "--cluster"
      cluster = client.get_cluster cluster_id
      return plan(cluster.provider_id)
    end

    if last_arg? "--ha"
      return ["true", "false"]
    end

    if last_arg? "-v", "--version"
      return [] of String
    end

    storage_suggest.tap { |s| return s if s }

    suggest = [] of String
    suggest << "--help\tshow help" if args.size == 3
    suggest << "--cluster\tcluster id" unless has_full_flag? :cluster
    suggest << "--confirm\tconfirm upgrade" unless has_full_flag? :confirm
    suggest << "--ha\thigh availability" unless has_full_flag? :ha
    suggest << "--plan\tplan" unless has_full_flag? :plan
    suggest << "--storage\tsize in GiB" unless has_full_flag? :storage
    suggest << "--version\tpostgres major version" unless has_full_flag? :version
    suggest
  end

  def uri
    return cluster_suggestions if @args.size == 2

    if last_arg? "--role"
      return Role::VALID_CLUSTER_ROLES.to_a
    end

    suggest = [] of String
    suggest << "--role\trole name" unless has_full_flag? :role
    suggest
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
    full << :confirm if has_full_flag? "--confirm"
    full << :read_only if has_full_flag? "--read-only"
    full << :role if has_full_flag? "--role"
    full << :rotate_password if has_full_flag? "--rotate-password"
    full << :enforce_sso if has_full_flag? "--enforce-sso"
    full << :billing_email if has_full_flag? "--billing-email"
    full << :account if has_full_flag? "--account"
    full << :email if has_full_flag? "--email"
    full << :full if has_full_flag? "--full"
    full << :format if has_full_flag? "--format"
    full << :authkey if has_full_flag? "--authkey"
    full << :window_start if has_full_flag? "--window-start"
    full << :unset if has_full_flag? "--unset"
    full << :no_header if has_full_flag? "--no-header"
    full
  end

  def has_full_flag?(arg1 : String, arg2 : String? = nil) : Bool
    idx = @args.index(arg1) || @args.index(arg2)
    return false unless idx
    !@args[idx + 1]?.nil?
  end

  def has_full_flag?(*names : Symbol) : Bool
    names.all? { |n| @full_flags.includes? n }
  end

  def last_arg?(*args) : Bool
    last = @args[-2]
    args.includes? last
  end
end
