#!/usr/bin/env crystal
require "./cb"
require "./ext/option_parser"
require "raven"

Log.setup do |c|
  c.bind("raven.*", Log::Severity::None, Log::IOBackend.new)
  c.bind "*", :info, Raven::LogBackend.new(record_breadcrumbs: true)
end

PROG = CB::Program.new

macro set_action(cl)
  action = CB::{{cl}}.new PROG.client, PROG.input, PROG.output
end

macro positional_args(*action_setters)
  parser.unknown_args do |args|
    unless args.size == {{action_setters.size}}
      STDERR.puts parser
      exit 1
    end
    {% for setter, idx in action_setters %}
      {{setter}} = args[{{idx}}]
    {% end %}
  end
end

def show_deprecated(msg : String)
  printf "%s: %s\n\n", "Deprecated".colorize.t_warn, msg
end

Raven.configure do |config|
  {% if flag?(:release) %}
    config.dsn = String.new(Bytes[
      104, 116, 116, 112, 115, 58, 47, 47, 99, 56, 101, 102, 56, 99, 57, 57,
      48, 100, 52, 57, 52, 48, 102, 50, 97, 49, 53, 55, 48, 52, 102, 101, 100,
      52, 100, 51, 53, 52, 55, 56, 64, 111, 52, 51, 51, 52, 53, 49, 46, 105,
      110, 103, 101, 115, 116, 46, 115, 101, 110, 116, 114, 121, 46, 105, 111,
      47, 53, 56, 51, 49, 51, 51, 49,
    ])
  {% end %}
  config.release = CB::VERSION
  config.server_name = CB::HOST
end

action = nil
op = OptionParser.new do |parser|
  parser.banner = "cb <command>"

  parser.on("--_completion CMDSTRING") do |cmdstring|
    client = PROG.client rescue nil # in case not logged in
    CB::Completion.parse(client, cmdstring).each { |opt| puts opt }
    exit
  end

  parser.on("login", "Store API key") do
    parser.banner = "cb login"
    action = CB::Login.new
  end

  parser.on("logout", "Remove stored API key and tokens") do
    parser.banner = "cb logout"
    action = CB::Logout.new
  end

  parser.on("list", "List clusters") do
    parser.banner = "cb list"
    set_action List
  end

  parser.on("info", "Detailed cluster information") do
    parser.banner = "cb info <cluster id>"
    info = set_action ClusterInfo
    positional_args info.cluster_id
  end

  # Opens the Bridge dashboard.
  #
  # This is hidden from help because it's largely used for internal use.
  parser.on("open") do
    parser.banner = "cb open"
    set_action Open
  end

  parser.on("rename", "Change cluster name") do
    parser.banner = "cb rename <cluster id> <new name>"
    rename = set_action ClusterRename

    positional_args rename.cluster_id, rename.new_name
  end

  parser.on("uri", "Display connection URI for a cluster") do
    parser.banner = "cb uri <cluster id> [--role]"
    uri = set_action ClusterURI

    parser.on("--role NAME", "Role name (default: default)") { |arg| uri.role = CB::Role.new arg }
    positional_args uri.cluster_id
  end

  parser.on("psql", "Connect to the database using `psql`") do
    parser.banner = "cb psql <cluster id> [--database] [-- [args for psql such as -c or -f]]"
    psql = set_action Psql

    parser.on("--database NAME", "Database name (default: postgres)") { |arg| psql.database = arg }
    parser.on("--role NAME", "Role name (default: default)") { |arg| psql.role = arg }
    positional_args psql.cluster_id
  end

  parser.on("firewall", "Manage firewall rules") do
    manage = set_action ManageFirewall
    parser.banner = "cb firewall <--cluster> [--add] [--remove]"

    parser.on("--cluster ID", "Choose cluster") { |arg| manage.cluster_id = arg }
    parser.on("--add CIDR", "Add a firewall rule") { |arg| manage.add arg }
    parser.on("--remove CIDR", "Remove a firewall rule") { |arg| manage.remove arg }
  end

  parser.on("create", "Create a new cluster") do
    create = set_action ClusterCreate
    parser.banner = <<-EOB
      cb create <--platform|-p> <--region|-r> <--plan> <--team|-t> [--size|-s] [--name|-n] [--version|-v] [--ha] [--network]
             cb create --fork ID [--at] [--platform|-p] [--region|-r] [--plan] [--size|-s] [--name|-n] [--ha] [--network]
             cb create --replica ID [--platform|-p] [--region|-r] [--plan] [--name|-n] [--network]
    EOB

    parser.on("--ha <true|false>", "High Availability (default: false)") { |arg| create.ha = arg }
    parser.on("--plan NAME", "Plan (server vCPU+memory)") { |arg| create.plan = arg }
    parser.on("-n NAME", "--name NAME", "Cluster name (default: Cluster date+time)") { |arg| create.name = arg }
    parser.on("-p NAME", "--platform NAME", "Cloud provider") { |arg| create.platform = arg }
    parser.on("-r NAME", "--region NAME", "Region/Location") { |arg| create.region = arg }
    parser.on("-v VERSION", "--version VERSION", "Postgres major version") { |arg| create.postgres_version = arg }
    parser.on("-s GiB", "--storage GiB", "Storage size (default: 100GiB, or same as source)") { |arg| create.storage = arg }
    parser.on("-t ID", "--team ID", "Team") { |arg| create.team = arg }
    parser.on("--network network", "Network") { |arg| create.network = arg }

    parser.on("--replica ID", "Choose source cluster for read-replica") { |arg| create.replica = arg }
    parser.on("--fork ID", "Choose source cluster for fork") { |arg| create.fork = arg }
    parser.on("--at TIME", "Recovery point-in-time in RFC3339 (default: now)") { |arg| create.at = arg }
  end

  # Cluster Upgrade
  parser.on("upgrade", "Manage a cluster upgrades") do
    parser.on("start", "Start a cluster upgrade") do
      upgrade = set_action UpgradeStart
      parser.banner = "cb upgrade start <--cluster>"

      parser.on("--cluster ID", "Choose cluster") { |arg| upgrade.cluster_id = arg }
      parser.on("--ha <true|false>", "High Availability") { |arg| upgrade.ha = arg }
      parser.on("-v VERSION", "--version VERSION", "Postgres major version") { |arg| upgrade.postgres_version = arg }
      parser.on("--plan NAME", "Plan (server vCPU+memory)") { |arg| upgrade.plan = arg }
      parser.on("-s GiB", "--storage GiB", "Storage size") { |arg| upgrade.storage = arg }
      parser.on("--starting-from START", "Starting time of upgrade. (RFC3339 format)") { |arg| upgrade.starting_from = arg }
      parser.on("--now", "Start the upgrade now") { |_| upgrade.now = true }
      parser.on("--confirm", "Confirm cluster restart") do
        upgrade.confirmed = true
      end
    end

    parser.on("cancel", "Cancel a cluster upgrade") do
      upgrade = set_action UpgradeCancel
      parser.banner = "cb upgrade cancel <--cluster>"

      parser.on("--cluster ID", "Choose cluster") { |arg| upgrade.cluster_id = arg }
    end

    parser.on("status", "Show cluster upgrade status") do
      upgrade = set_action UpgradeStatus
      parser.banner = "cb upgrade status <--cluster>"

      parser.on("--cluster ID", "Choose cluster") { |arg| upgrade.cluster_id = arg }
    end

    parser
  end

  parser.on("destroy", "Destroy a cluster") do
    parser.banner = "cb destroy <cluster id>"
    destroy = set_action ClusterDestroy

    positional_args destroy.cluster_id
  end

  parser.on("detach", "Detach a cluster") do
    detach = set_action Detach
    parser.banner = "cb detach <cluster id>"

    parser.on("--confirm", "Confirm cluster detach") do
      detach.confirmed = true
    end

    positional_args detach.cluster_id
  end

  parser.on("restart", "Restart a cluster") do
    restart = set_action Restart
    parser.banner = "cb restart <cluster id> [--confirm] [--full]"

    parser.on("--confirm", "Confirm cluster restart") { restart.confirmed = true }
    parser.on("--full", "Full restart of server") { restart.full = true }

    positional_args restart.cluster_id
  end

  parser.on("scope", "Run diagnostic queries on a cluster") do
    parser.banner = "cb scope <--cluster> [--(check),...]"
    scope = set_action Scope
    parser.on("--cluster ID", "Choose cluster") { |arg| scope.cluster_id = arg }
    parser.on("--suite <all|quick>", "Run suite of scopes (default: quick)") { |arg| scope.suite = arg }
    parser.on("--database NAME", "Database name (default: postgres)") { |arg| scope.database = arg }
    Scope::Check.all.each do |ck|
      parser.on(ck.flag, ck.desc) { scope.checks << ck.type }
    end
  end

  parser.on("logs", "View live cluster logs") do
    parser.banner = "cb logs <cluster>"
    logs = set_action Logs

    positional_args logs.cluster_id
  end

  parser.on("logdest", "Manage log destinations") do
    parser.banner = "cb logdest <list|add|destroy>"

    parser.on("list", "List log destinations for a cluster") do
      list = set_action LogDestinationList
      parser.banner = "cb logdest list <--cluster>"
      parser.on("--cluster ID", "Choose cluster") { |arg| list.cluster_id = arg }
    end

    parser.on("add", "Add a new log destination to a cluster") do
      add = set_action LogDestinationAdd
      parser.banner = "cb logdest add <--cluster> <--host> <--port> <--template> [--desc]"
      parser.on("--cluster ID", "Choose cluster") { |arg| add.cluster_id = arg }
      parser.on("--host HOST", "Hostname") { |arg| add.host = arg }
      parser.on("--port PORT", "Port number") { |arg| add.port = arg }
      parser.on("--template STR", "Log template") { |arg| add.template = arg }
      parser.on("--desc STR", "Description") { |arg| add.description = arg }
    end

    parser.on("destroy", "Remove an existing log destination from a cluster") do
      destroy = set_action LogDestinationDestroy
      parser.banner = "cb logdest destroy <--cluster> <--logdest>"
      parser.on("--cluster ID", "Choose cluster") { |arg| destroy.cluster_id = arg }
      parser.on("--logdest ID", "Choose log destination") { |arg| destroy.logdest_id = arg }
    end
  end

  #
  # Cluster maintenance Management
  #

  parser.on("maintenance", "Manage cluster maintenance") do
    parser.banner = "cb maintenance <info|set|cancel>"

    parser.on("info", "Display cluster maintenance information") do
      upgrade = set_action UpgradeStatus
      upgrade.maintenance_only = true

      parser.banner = "cb maintenance info <--cluster>"
      parser.on("--cluster ID", "Choose cluster") { |arg| upgrade.cluster_id = arg }
    end

    parser.on("cancel", "Cancel a cluster maintenance") do
      upgrade = set_action UpgradeCancel
      parser.banner = "cb maintenance cancel <--cluster>"

      parser.on("--cluster ID", "Choose cluster") { |arg| upgrade.cluster_id = arg }
    end

    parser.on("set", "Update the cluster default maintenance window") do
      update = set_action MaintenanceWindowUpdate
      parser.banner = "cb maintenance set <--cluster> [--window-start] [--unset]"
      parser.on("--cluster ID", "Choose cluster") { |arg| update.cluster_id = arg }
      parser.on("--window-start START", "Hour maintenance window start (UTC)") { |arg| update.window_start = arg }
      parser.on("--unset", "Unset mainetnance window") { |_| update.unset = true }
    end
  end

  #
  # Network Management
  #

  parser.on("network", "Manage networks") do
    parser.banner = "cb network <info|list>"

    parser.on("info", "Detailed network information") do
      info = set_action NetworkInfo

      parser.banner = "cb network info <--network>"

      parser.on("--network ID", "Choose network") { |arg| info.network_id = arg }
      parser.on("--format FORMAT", "Choose output format (default: table)") { |arg| info.format = arg }
      parser.on("--no-header", "Do not display table header") { info.no_header = true }

      parser.examples = <<-EXAMPLES
      Get network details. Ouptut: table
      $ cb network info --network <ID>

      Get network details. Output: table without header
      $ cb network info --network <ID> --no-header

      Get network details. Output: json
      $ cb network info --network <ID> --format=json
      EXAMPLES
    end

    parser.on("list", "List all networks") do
      list = set_action NetworkList

      parser.banner = "cb network list [--team]"

      parser.on("--team ID", "Choose team") { |arg| list.team_id = arg }
      parser.on("--format FORMAT", "Choose output format (default: table)") { |arg| list.format = arg }
      parser.on("--no-header", "Do not display table header") { list.no_header = true }

      parser.examples = <<-EXAMPLES
      List all networks for personal team (or preferred team if using SSO). Output: table
      $ cb network list

      List all networks for a specific team. Output: table
      $ cb network list --team <ID>

      List all networks for a specific team. Ouptut: table without header
      $ cb network list --team <ID> --no-header

      List all networks for a specific team. Output: json
      $ cb network list --team <ID> --format=json
      EXAMPLES
    end
  end

  #
  # Cluster Tailscale Management
  #

  parser.on("tailscale", "Manage Tailscale") do
    parser.banner = "cb tailscale <connect|disconnect>"

    parser.on("connect", "Add a cluster to Tailscale") do
      connect = set_action TailscaleConnect
      parser.banner = "cb tailscale connect <--cluster> <--authkey>"
      parser.on("--cluster ID", "Choose cluster") { |arg| connect.cluster_id = arg }
      parser.on("--authkey KEY", "Pre-authentication key") { |arg| connect.auth_key = arg }
    end

    parser.on("disconnect", "Remove a cluster from Tailscale") do
      disconnect = set_action TailscaleDisconnect
      parser.banner = "cb tailscale disconnect <--cluster>"
      parser.on("--cluster ID", "Choose cluster") { |arg| disconnect.cluster_id = arg }
    end
  end

  #
  # Cluster Role Management
  #

  parser.on("role", "Manage cluster roles") do
    parser.banner = "cb role <create|update|destroy>"

    parser.on("create", "Create new role for a cluster") do
      create = set_action RoleCreate
      parser.banner = "cb role create <--cluster>"
      parser.on("--cluster ID", "Choose cluster") { |arg| create.cluster_id = arg }
    end

    parser.on("destroy", "Destroy a cluster role") do
      destroy = set_action RoleDelete
      parser.banner = "cb role destroy <--cluster> <--name>"
      parser.on("--cluster ID", "Choose cluster") { |arg| destroy.cluster_id = arg }
      parser.on("--name NAME", "Role name") { |arg| destroy.role = arg }
    end

    parser.on("list", "List cluster roles") do
      list = set_action RoleList
      parser.banner = "cb role list <--cluster>"
      parser.on("--cluster ID", "Choose cluster") { |arg| list.cluster_id = arg }
      parser.on("--format FORMAT", "Choose output format (default: table)") { |arg| list.format = arg }
      parser.on("--no-header", "Do not display table header") { |arg| list.no_header = true }

      parser.examples = <<-EXAMPLES
        Get roles for a cluster. Output: table
        $ cb role list --cluster <ID>

        Get roles for a cluster. Output: table without header
        $ cb role list --cluster <ID> --no-header

        Get roles for a cluster. Output: json
        $ cb role list --cluster <ID> --format=json
      EXAMPLES
    end

    parser.on("update", "Update a cluster role") do
      update = set_action RoleUpdate
      parser.banner = "cb role update <--cluster> <--name> [--mode] [--rotate-password]"
      parser.on("--cluster ID", "Choose cluster") { |arg| update.cluster_id = arg }
      parser.on("--name NAME", "Role name") { |arg| update.role = arg }
      parser.on("--read-only <true|false>", "Read-only") { |arg| update.read_only = arg }
      parser.on("--rotate-password <true|false>", "Rotate password") { |arg| update.rotate_password = arg }
    end
  end

  #
  # Team Management
  #
  parser.on("team", "Manage teams") do
    parser.banner = "cb team <command>"

    parser.on("create", "Create a new team.") do
      create = set_action TeamCreate
      parser.banner = "cb team create <--name>"

      parser.on("--name NAME", "Team name") { |arg| create.name = arg }
    end

    parser.on("list", "List available teams.") do
      set_action TeamList
      parser.banner = "cb team list"
    end

    parser.on("info", "Show a teams details.") do
      info = set_action TeamInfo
      parser.banner = "cb team info <team id>"

      positional_args info.team_id
    end

    parser.on("update", "Update a team.") do
      update = set_action TeamUpdate
      parser.banner = "cb team update <team id> [options]"

      parser.on("--billing-email EMAIL", "Team billing email address.") { |arg| update.billing_email = arg }
      parser.on("--enforce-sso <true|false>", "Enforce SSO access to team.") { |arg| update.enforce_sso = arg }
      parser.on("--name NAME", "Name of the team.") { |arg| update.name = arg }
      parser.on("--confirm", "Confirm team update.") { |_| update.confirmed = true }
      positional_args update.team_id
    end

    parser.on("destroy", "Delete a team.") do
      destroy = set_action TeamDestroy
      parser.banner = "cb team destroy <team id> [options]"

      parser.on("--confirm", "Confirm team deletion.") { destroy.confirmed = true }
      positional_args destroy.team_id
    end
  end

  #
  # Team Member Management
  #

  parser.on("team-member", "Manage team members") do
    parser.banner = "cb team-member <command>"

    parser.on("add", "Add a team member") do
      add = set_action TeamMemberAdd
      parser.banner = "cb team-member add <--team> <--email> [--role]"

      parser.on("--team ID", "Team ID") { |arg| add.team_id = arg }
      parser.on("--email EMAIL", "User email address") { |arg| add.email = arg }
      parser.on("--role ROLE", "Team member role (default: member)") { |arg| add.role = arg }
    end

    parser.on("list", "List members of a team") do
      list = set_action TeamMemberList
      parser.banner = "cb team-member list <--team>"

      parser.on("--team ID", "Team ID") { |arg| list.team_id = arg }
    end

    parser.on("info", "Show team member details") do
      info = set_action TeamMemberInfo
      parser.banner = "cb team-member info <--team> <--account | --email>"

      parser.on("--team ID", "Team ID") { |arg| info.team_id = arg }
      parser.on("--account ID", "Account ID") { |arg| info.account_id = arg }
      parser.on("--email EMAIL", "User email address") { |arg| info.email = arg }
    end

    parser.on("update", "Update a member of a team") do
      update = set_action TeamMemberUpdate
      parser.banner = "cb team-member update <--team> <--account | --email> [options]"

      parser.on("--team ID", "Team ID") { |arg| update.team_id = arg }
      parser.on("--account ID", "Account ID") { |arg| update.account_id = arg }
      parser.on("--email EMAIL", "User email address") { |arg| update.email = arg }
      parser.on("--role ROLE", "Team member role") { |arg| update.role = arg }
    end

    parser.on("remove", "Remove a member from a team") do
      remove = set_action TeamMemberRemove
      parser.banner = "cb team-member remove <--team> <--account | --email>"

      parser.on("--team ID", "Team ID") { |arg| remove.team_id = arg }
      parser.on("--account ID", "Account ID") { |arg| remove.account_id = arg }
      parser.on("--email EMAIL", "User email address") { |arg| remove.email = arg }
    end
  end

  #
  # Backup Management
  #
  parser.on("backup", "Manage backups") do
    parser.banner = "cb backup <capture|list|token>"

    parser.on("capture", "Start capturing a new backup for a cluster") do
      capture = set_action BackupCapture
      parser.banner = "cb backup capture <cluster id>"
      positional_args capture.cluster_id
    end

    parser.on("list", "List backups for a cluster") do
      list = set_action BackupList
      parser.banner = "cb backup list <cluster id>"
      positional_args list.cluster_id
    end

    parser.on("token", "Create backup token") do
      token = set_action BackupToken
      parser.on("--format=FORMAT", "<default|pgbackrest>") { |arg| token.format = arg }
      parser.banner = "cb backup token <cluster id>"
      positional_args token.cluster_id
    end
  end

  parser.on("suspend", "Temporarily turn off a cluster") do
    parser.banner = "cb suspend <cluster id>"
    suspend = set_action ClusterSuspend
    positional_args suspend.cluster_id
  end

  parser.on("resume", "Turn on a previously suspended cluster") do
    parser.banner = "cb resume <cluster id>"
    resume = set_action ClusterResume
    positional_args resume.cluster_id
  end

  parser.on("teamcert", "Show public TLS cert for a team") do
    parser.banner = "cb teamcert <team id>"
    teamcert = set_action TeamCert
    positional_args teamcert.team_id
  end

  parser.on("whoami", "Information on current user") do
    set_action WhoAmI
  end

  parser.on("token", "Return a bearer token for use in the api") do
    parser.banner = "cb token [-H]"
    token = action = CB::TokenAction.new PROG.token, PROG.input, PROG.output

    parser.on("-H", "Authorization header format") { token.with_header = true }
  end

  parser.on("version", "Show the version") do
    parser.banner = "cb version"
    puts CB::VERSION_STR
    exit
  end

  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end

  parser.invalid_option do |flag|
    STDERR << "error".colorize.t_warn << ": " << flag.colorize.t_name << " is not a valid option.\n"
    STDERR.puts parser
    exit 1
  end

  parser.missing_option do |flag|
    STDERR << "error".colorize.t_warn << ": " << flag.colorize.t_name << " requires a value.\n"
    STDERR.puts parser
    exit 1
  end
end

def capture_error(e)
  return if e.class == Raven::Error
  begin
    # make sure error gets annotated with user id, but don’t fail to capture if
    # some error in this process
    t = PROG.token
    Raven.user_context id: t.user_id
  rescue
  end

  cap = Raven.capture e
  if cap.class == Raven::Event
    cap = cap.as(Raven::Event)
    STDERR.puts "#{"error".colorize.red.bold}: #{e.message}"
    STDERR.puts "   #{"id".colorize.red.bold}: #{cap.id.colorize.t_id}"
  else
    raise e
  end
end

begin
  op.parse
  if a = action
    a.call
  else
    puts op
    exit
  end
rescue e : CB::Program::Error
  STDERR.puts "#{"error".colorize.red.bold}: #{e.message}"
  STDERR.puts op if e.show_usage

  exit 1
rescue e : CB::Client::Error
  if e.unauthorized?
    if PROG.ensure_token_still_good
      STDERR << "error".colorize.t_warn << ": Token had expired, but has been refreshed. Please try again.\n"
      exit 1
    end
  end
  STDERR.puts e
  exit 2
rescue e
  capture_error e
  exit 3
end
