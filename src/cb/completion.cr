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
      when "info", "rename", "logs", "suspend", "resume"
        single_cluster_suggestion
      when "config-param"
        config_param
      when "create"
        create
      when "destroy"
        destroy_cluster
      when "detach"
        detach
      when "firewall"
        firewall
      when "logdest"
        logdest
      when "list"
        list_clusters
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
      when "token"
        token
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
      "upgrade\tManage cluster upgrades",
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
      "config-param\tManage configuration parameters",
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
    clusters = client.get_clusters(teams, true)

    clusters.map do |c|
      team_name = teams.find { |t| t.id == c.team_id }.try(&.name) || "unknown_team"
      "#{c.id}\t#{team_name}/#{c.name}"
    end
  end

  def network_suggestions
    teams = client.get_teams
    networks = client.get_networks(teams)

    networks.map do |n|
      team_name = teams.find { |t| t.id == n.team_id }.try(&.name) || "unknown_team"
      "#{n.id}\t#{n.name}"
    end
  end

  def firewall_rule_suggestions(network_id : String?)
    rules = client.get_firewall_rules(network_id)
    rules.map { |r| "#{r.id}\t#{r.description}" }
  end

  def teams
    client.get_teams.map { |t| "#{t.id}\t#{t.name}" }
  end

  def create_fork_suggest
    return cluster_suggestions if last_arg? "--fork"
    return suggest_none if last_arg? "--at"

    platform_region_plan_suggest.tap { |s| return s if s }
    storage_suggest.tap { |s| return s if s }

    suggest = [] of String
    suggest << "--at\tPITR time in RFC3339" unless has_full_flag?(:at)
    suggest << "--ha\thigh availability" unless has_full_flag?(:ha)
    suggest << "--help\tshow help" if args.size == 2
    suggest << "--name\tcluster name" unless has_full_flag? :name
    suggest << "--network\tnetwork id" unless has_full_flag? :network
    suggest << "--platform\tcloud provider" unless has_full_flag? :platform
    suggest << "--storage\tstorage size in GiB" unless has_full_flag?(:storage) || has_full_flag?(:replica)
    suggest << "--version\tmajor version" unless has_full_flag?(:version) || has_full_flag?(:fork) || has_full_flag?(:replica)
    suggest
  end

  def create_replica_suggest
    if last_arg? "--replica"
      return cluster_suggestions
    end

    platform_region_plan_suggest.tap { |s| return s if s }

    suggest = [] of String
    suggest << "--help\tshow help" if args.size == 2
    suggest << "--name\tcluster name" unless has_full_flag? :name
    suggest << "--network\tnetwork id" unless has_full_flag? :network
    suggest << "--platform\tcloud provider" unless has_full_flag? :platform
    suggest
  end

  def create_standalone_suggest
    return teams if last_arg? "-t", "--team"

    platform_region_plan_suggest.tap { |s| return s if s }
    storage_suggest.tap { |s| return s if s }

    suggest = [] of String
    suggest << "--fork\tcluster to fork" unless has_full_flag?(:fork) || has_full_flag?(:replica)
    suggest << "--ha\thigh availability" unless has_full_flag?(:ha) || has_full_flag?(:replica)
    suggest << "--help\tshow help" if args.size == 2
    suggest << "--name\tcluster name" unless has_full_flag? :name
    suggest << "--network\tnetwork id" unless has_full_flag? :network
    suggest << "--platform\tcloud provider" unless has_full_flag? :platform
    suggest << "--replica\tcluster create read-reaplica from" unless has_full_flag?(:fork) || has_full_flag?(:replica)
    suggest << "--storage\tstorage size in GiB" unless has_full_flag?(:storage) || has_full_flag?(:replica)
    suggest << "--team\tcrunchy bridge team" unless has_full_flag?(:team)
    suggest << "--version\tmajor version" unless has_full_flag?(:version)
    suggest
  end

  def create
    return suggest_none if args.includes? "--help"

    return suggest_bool if last_arg? "--ha"
    return suggest_none if last_arg? "-n", "--name"
    return suggest_none if last_arg? "--network"
    return suggest_none if last_arg? "-v", "--version"

    create_fork_suggest.tap { |s| return s if s } if args.includes? "--fork"
    create_replica_suggest.tap { |s| return s if s } if args.includes? "--replica"
    create_standalone_suggest.tap { |s| return s if s }
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

  def destroy_cluster
    return cluster_suggestions if @args.size == 2

    suggest = [] of String
    suggest << "--confirm\tconfirm cluster #{@args.first}" unless has_full_flag? :confirm
    suggest
  end

  def list_clusters
    if last_arg?("--team")
      return team_suggestions
    end

    if last_arg?("--format")
      return [CB::Format::Table, CB::Format::Tree].map(&.to_s.downcase)
    end

    suggest = [] of String
    suggest << "--team\tteam id" unless has_full_flag? :team
    suggest << "--format\tchoose output format" unless has_full_flag? :format
    suggest
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

  def firewall_rules(network_id)
    rules = client.get_firewall_rules(network_id)
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

  def token : Array(String)
    suggest_none if last_arg?("-H")
    return ["header", "json"] if last_arg?("--format")

    suggest = [] of String
    suggest << "-H\toutput header format" unless has_full_flag? :header
    suggest << "--format\tchoose output format" unless has_full_flag? :format
    suggest
  end

  def config_param
    case @args[1]
    when "get"
      config_param_get
    when "list-supported"
      config_param_list_supported
    when "reset"
      config_param_reset
    when "set"
      config_param_set
    else
      [
        "get\tdisplay configuration parameters",
        "list-supported\tdisplay supported configuration parameters",
        "reset\treset configuration parameters to the default value",
        "set\tset configuration parameters",
      ]
    end
  end

  def config_param_get
    cluster = find_arg_value "--cluster"

    if last_arg?("--cluster")
      return cluster.nil? ? cluster_suggestions : [] of String
    end

    if last_arg?("--format")
      return ["json", "table"]
    end

    suggest = [] of String
    suggest << "--cluster\tcluster id" unless has_full_flag? :cluster
    suggest << "--format\toutput format" unless has_full_flag? :format
    suggest
  end

  def config_param_list_supported
    return ["json", "table"] if last_arg?("--format")

    suggest = [] of String
    suggest << "--format\toutput format" unless has_full_flag? :format
    suggest
  end

  def config_param_reset
    return ["false", "true"] if last_arg?("--allow-restart")

    if last_arg?("--cluster")
      cluster = find_arg_value "--cluster"
      return cluster.nil? ? cluster_suggestions : [] of String
    end

    return ["json", "table"] if last_arg?("--format")

    suggest = [] of String
    suggest << "--allow-restart\tallow restart" unless has_full_flag? :allow_restart
    suggest << "--cluster\tcluster id" unless has_full_flag? :cluster
    suggest << "--format\toutput format" unless has_full_flag? :format
    suggest
  end

  def config_param_set
    return ["false", "true"] if last_arg?("--allow-restart")

    if last_arg?("--cluster")
      cluster = find_arg_value "--cluster"
      return cluster.nil? ? cluster_suggestions : [] of String
    end

    return ["json", "table"] if last_arg?("--format")

    suggest = [] of String
    suggest << "--allow-restart\tallow restart" unless has_full_flag? :allow_restart
    suggest << "--cluster\tcluster id" unless has_full_flag? :cluster
    suggest << "--format\toutput format" unless has_full_flag? :format
    suggest
  end

  def maintenance
    case @args[1]
    when "info"
      upgrade_status
    when "set"
      maintenance_window_update
    when "cancel"
      upgrade_cancel
    when "create"
      maintenance_create
    when "update"
      maintenance_update
    else
      [
        "info\tdisplay cluster maintenance information",
        "set\tupdate the cluster default maintenance window",
        "cancel\tcancel a cluster maintenance",
        "create\tcreate a cluster maintenance",
        "update\tupdate a pending cluster maintenance",
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
    suggest << "--unset\tUnset maintenance window" unless has_full_flag?(:unset) || has_full_flag?(:window_start)
    suggest
  end

  def maintenance_create : Array(String)
    cluster = find_arg_value "--cluster"

    if last_arg?("--cluster")
      return cluster.nil? ? cluster_suggestions : [] of String
    end

    if last_arg?("--starting-from", "--now")
      suggest_none
    end

    suggest = [] of String
    suggest << "--cluster\tcluster id" unless has_full_flag? :cluster
    suggest << "--starting-from\tStarting time to schedule a maintenance. (RFC3339 format)" unless has_full_flag?(:now) || has_full_flag?(:starting_from)
    suggest << "--now\tStart a maintenance now" unless has_full_flag?(:now) || has_full_flag?(:starting_from)
    suggest
  end

  def maintenance_update : Array(String)
    cluster = find_arg_value "--cluster"

    if last_arg?("--cluster")
      return cluster.nil? ? cluster_suggestions : [] of String
    end

    if last_arg?("--starting-from", "--now", "--use-cluster-maintenance-window")
      suggest_none
    end

    maintenance_window_option = has_full_flag?(:now) || has_full_flag?(:starting_from) || has_full_flag?(:use_cluster_maintenance_window)
    suggest = [] of String
    suggest << "--cluster\tcluster id" unless has_full_flag? :cluster
    suggest << "--starting-from\tStarting time to schedule a maintenance. (RFC3339 format)" unless maintenance_window_option
    suggest << "--now\tStart a maintenance now" unless maintenance_window_option
    suggest << "--use-cluster-maintenance-window\tUse cluster maintenance window" unless maintenance_window_option

    suggest
  end

  def network
    case @args[1]
    when "add-firewall-rule"
      network_add_firewall_rule
    when "list-firewall-rules"
      network_list_firewall_rules
    when "remove-firewall-rule"
      network_remove_firewall_rule
    when "update-firewall-rule"
      network_update_firewall_rule
    when "info"
      network_info
    when "list"
      network_list
    else
      [
        "add-firewall-rule\tadd firewall rule",
        "remove-firewall-rule\tremove firewall rule",
        "list-firewall-rules\tlist firewall rules",
        "update-firewall-rule\tupdate firewall rule",
        "info\tdetailed network information",
        "list\tlist available networks",
      ]
    end
  end

  def network_add_firewall_rule
    return ["table", "json"] if last_arg?("--format")
    return network_suggestions if last_arg?("--network")
    suggest = [] of String
    suggest << "--description\tdescription of rule to add" unless has_full_flag? :description
    suggest << "--format\tchoose output format" unless has_full_flag? :format
    suggest << "--network\tnetwork id" unless has_full_flag? :network
    suggest << "--rule\tcidr of rule to add" unless has_full_flag? :rule
    suggest
  end

  def network_remove_firewall_rule
    if last_arg?("--firewall-rule") && has_full_flag?(:network)
      network = find_arg_value "--network"
      return firewall_rule_suggestions(network)
    end

    return ["table", "json"] if last_arg?("--format")
    return network_suggestions if last_arg?("--network")
    suggest = [] of String
    suggest << "--firewall-rule\tchoose firewall rule" unless has_full_flag?(:firewall_rule)
    suggest << "--format\tchoose output format" unless has_full_flag? :format
    suggest << "--network\tchoose network" unless has_full_flag? :network
    suggest
  end

  def network_list_firewall_rules
    return ["table", "json"] if last_arg?("--format")
    return network_suggestions if last_arg?("--network")
    suggest = [] of String
    suggest << "--format\tchoose output format" unless has_full_flag? :format
    suggest << "--network\tchoose network" unless has_full_flag? :network
    suggest
  end

  def network_update_firewall_rule
    if last_arg?("--firewall-rule") && has_full_flag?(:network)
      network = find_arg_value "--network"
      return firewall_rule_suggestions(network)
    end

    return ["table", "json"] if last_arg?("--format")
    return network_suggestions if last_arg?("--network")

    suggest = [] of String
    suggest << "--description\tdescription of the rule" unless has_full_flag? :description
    suggest << "--firewall-rule\tchoose firewall rule" unless has_full_flag?(:firewall_rule)
    suggest << "--format\tchoose output format" unless has_full_flag? :format
    suggest << "--network\tchoose network" unless has_full_flag? :network
    suggest << "--rule\tcidr of the rule" unless has_full_flag? :rule
    suggest
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
    when "update"
      upgrade_update
    else
      [
        "start\tstart cluster upgrade",
        "cancel\tcancel cluster upgrade",
        "status\tshow status of cluster upgrade",
        "update\tupdate a pending cluster upgrade",
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

    return suggest if has_full_flag? :ha

    upgrade_flags = %i[plan storage starting_from now version]
    if upgrade_flags.none? { |flag| has_full_flag? flag }
      suggest << "--ha\thigh availability"
    end

    suggest << "--plan\tplan" unless has_full_flag? :plan
    suggest << "--storage\tsize in GiB" unless has_full_flag? :storage
    suggest << "--starting-from\tstarting time of upgrade. (RFC3339 format)" unless has_full_flag?(:starting_from) || has_full_flag?(:now)
    suggest << "--now\tstart the upgrade now" unless has_full_flag?(:now) || has_full_flag?(:starting_from)
    suggest << "--version\tpostgres major version" unless has_full_flag? :version
    suggest
  end

  def upgrade_update
    if last_arg? "--cluster"
      return cluster_suggestions
    end

    if last_arg? "--plan"
      cluster_id = find_arg_value "--cluster"
      cluster = client.get_cluster cluster_id
      return plan(cluster.provider_id)
    end

    if last_arg? "-v", "--version"
      return [] of String
    end

    storage_suggest.tap { |s| return s if s }

    if last_arg?("--starting-from", "--now", "--use-cluster-maintenance-window")
      suggest_none
    end

    maintenance_window_option = has_full_flag?(:now) || has_full_flag?(:starting_from) || has_full_flag?(:use_cluster_maintenance_window)

    suggest = [] of String
    suggest << "--help\tshow help" if args.size == 3
    suggest << "--cluster\tcluster id" unless has_full_flag? :cluster
    suggest << "--confirm\tconfirm upgrade" unless has_full_flag? :confirm
    suggest << "--plan\tplan" unless has_full_flag? :plan
    suggest << "--storage\tsize in GiB" unless has_full_flag? :storage
    suggest << "--starting-from\tstarting time of upgrade. (RFC3339 format)" unless has_full_flag?(:starting_from) || has_full_flag?(:now)
    suggest << "--now\tStart a maintenance now" unless maintenance_window_option
    suggest << "--version\tpostgres major version" unless has_full_flag? :version
    suggest << "--starting-from\tStarting time to schedule a maintenance. (RFC3339 format)" unless maintenance_window_option
    suggest << "--use-cluster-maintenance-window\tUse cluster maintenance window" unless maintenance_window_option

    suggest
  end

  def uri
    return cluster_suggestions if @args.size == 2

    suggest_none if last_arg? "--database"
    suggest_none if last_arg? "--port"

    if last_arg? "--role"
      return Role::VALID_CLUSTER_ROLES.to_a
    end

    suggest = [] of String
    suggest << "--database\tdatabase name" unless has_full_flag? :database
    suggest << "--port\tport number" unless has_full_flag? :port
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
    full << :allow_restart if has_full_flag? "--allow-restart"
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
    full << :header if has_full_flag? "-H"
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
    full << :starting_from if has_full_flag? "--starting-from"
    full << :now if has_full_flag? "--now"
    full << :use_cluster_maintenance_window if has_full_flag? "use-cluster-maintenance-window"
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
