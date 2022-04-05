#!/usr/bin/env crystal
require "./cb"
require "./option_parser"
require "raven"

Log.setup do |c|
  c.bind("raven.*", Log::Severity::None, Log::IOBackend.new)
  c.bind "*", :info, Raven::LogBackend.new(record_breadcrumbs: true)
end

PROG = CB::Program.new host: ENV["CB_HOST"]?

macro set_action(cl)
  action = CB::{{cl}}.new PROG.client
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
  config.server_name = PROG.host
end

action = nil
op = OptionParser.new do |parser|
  get_id_arg = ->(args : Array(String)) do
    if args.empty?
      STDERR.puts parser
      exit 1
    end
    args.first
  end

  parser.banner = "cb <command>"

  parser.on("--_completion CMDSTRING") do |cmdstring|
    client = PROG.client rescue nil # in case not logged in
    CB::Completion.parse(client, cmdstring).each { |opt| puts opt }
    exit
  end

  parser.on("login", "Store API key") do
    parser.banner = "cb login"
    action = ->{ PROG.login }
  end

  parser.on("list", "List clusters") do
    parser.banner = "cb list"
    set_action List
  end

  parser.on("info", "Detailed cluster information") do
    parser.banner = "cb info <cluster id>"
    info = set_action ClusterInfo

    parser.unknown_args do |args|
      info.cluster_id = get_id_arg.call(args)
    end
  end

  parser.on("rename", "Change cluster name") do
    parser.banner = "cb rename <cluster id> <new name>"
    rename = set_action ClusterRename

    parser.unknown_args do |args|
      unless args.size == 2
        STDERR.puts parser
        exit 1
      end
      rename.cluster_id = args.first
      rename.new_name = args.last
    end
  end

  parser.on("uri", "Display connection URI for a cluster") do
    parser.banner = "cb uri <cluster id> [--role]"
    uri = set_action ClusterURI

    parser.on("--role NAME", "Role name (default: default)") { |arg| uri.role_name = arg }

    parser.unknown_args do |args|
      uri.cluster_id = get_id_arg.call(args)
    end
  end

  parser.on("psql", "Connect to the database using `psql`") do
    parser.banner = "cb psql <cluster id> [--database] [-- [args for psql such as -c or -f]]"
    psql = set_action Psql

    parser.on("--database NAME", "Database name (default: postgres)") { |arg| psql.database = arg }

    parser.unknown_args do |args|
      psql.cluster_id = get_id_arg.call(args)
    end
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

    parser.unknown_args do |args|
      destroy.cluster_id = get_id_arg.call(args)
    end
  end

  parser.on("detach", "Detach a cluster") do
    detach = set_action Detach
    parser.banner = "cb detach <cluster id>"

    parser.on("--confirm", "Confirm cluster detach") do
      detach.confirmed = true
    end

    parser.unknown_args do |args|
      detach.cluster_id = get_id_arg.call(args)
    end
  end

  parser.on("restart", "Restart a cluster") do
    restart = set_action Restart
    parser.banner = "cb restart <cluster id> [--confirm]"

    parser.on("--confirm", "Confirm cluster restart") do
      restart.confirmed = true
    end

    parser.unknown_args do |args|
      restart.cluster_id = get_id_arg.call(args)
    end
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

  parser.on("logdest", "Manage log destinations") do
    parser.banner = "cb logdest <list|add|destroy>"

    parser.on("list", "List log destinations for a cluster") do
      list = set_action LogdestList
      parser.banner = "cb logdest list <--cluster>"
      parser.on("--cluster ID", "Choose cluster") { |arg| list.cluster_id = arg }
    end

    parser.on("add", "Add a new log destination to a cluster") do
      add = set_action LogdestAdd
      parser.banner = "cb logdest add <--cluster> <--host> <--port> <--template> [--desc]"
      parser.on("--cluster ID", "Choose cluster") { |arg| add.cluster_id = arg }
      parser.on("--host HOST", "Hostname") { |arg| add.host = arg }
      parser.on("--port PORT", "Port number") { |arg| add.port = arg }
      parser.on("--template STR", "Log template") { |arg| add.template = arg }
      parser.on("--desc STR", "Description") { |arg| add.desc = arg }
    end

    parser.on("destroy", "Remove an existing log destination from a cluster") do
      destroy = set_action LogdestDestroy
      parser.banner = "cb logdest destroy <--cluster> <--logdest>"
      parser.on("--cluster ID", "Choose cluster") { |arg| destroy.cluster_id = arg }
      parser.on("--logdest ID", "Choose log destination") { |arg| destroy.logdest_id = arg }
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

    parser.on("update", "Update a cluster role") do
      update = set_action RoleUpdate
      parser.banner = "cb role update <--cluster> <--name> [--mode] [--rotate-password]"
      parser.on("--cluster ID", "Choose cluster") { |arg| update.cluster_id = arg }
      parser.on("--name NAME", "Role name") { |arg| update.role_name = arg }
      parser.on("--read-only <true|false>", "Read-only") { |arg| update.read_only = arg }
      parser.on("--rotate-password <true|false>", "Rotate password") { |arg| update.rotate_password = arg }
    end

    parser.on("destroy", "Destroy a cluster role") do
      destroy = set_action RoleDelete
      parser.banner = "cb role destroy <--cluster> <--name>"
      parser.on("--cluster ID", "Choose cluster") { |arg| destroy.cluster_id = arg }
      parser.on("--name NAME", "Role name") { |arg| destroy.role_name = arg }
    end
  end

  #
  # Team Management
  #

  parser.on("teams") do
    parser.banner = "cb teams"
    set_action TeamList
    show_deprecated "Prefer use of 'cb team list' instead."
  end

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

      parser.unknown_args do |args|
        info.team_id = get_id_arg.call(args)
      end
    end

    parser.on("update", "Update a team.") do
      update = set_action TeamUpdate
      parser.banner = "cb team update <team id> [options]"

      parser.on("--billing-email EMAIL", "Team billing email address.") { |arg| update.billing_email = arg }
      parser.on("--enforce-sso <true|false>", "Enforce SSO access to team.") { |arg| update.enforce_sso = arg }
      parser.on("--name NAME", "Name of the team.") { |arg| update.name = arg }

      parser.on("--confirm", "Confirm team update.") { |arg| update.confirmed = true }

      parser.unknown_args do |args|
        update.team_id = get_id_arg.call(args)
      end
    end

    parser.on("destroy", "Delete a team.") do
      destroy = set_action TeamDestroy
      parser.banner = "cb team destroy <team id> [options]"

      parser.on("--confirm", "Confirm team deletion.") { destroy.confirmed = true }

      parser.unknown_args do |args|
        destroy.team_id = get_id_arg.call(args)
      end
    end
  end

  parser.on("teamcert", "Show public TLS cert for a team") do
    parser.banner = "cb teamcert <team id>"
    teamcert = set_action TeamCert

    parser.unknown_args do |args|
      teamcert.team_id = get_id_arg.call(args)
    end
  end

  parser.on("whoami", "Information on current user") do
    set_action WhoAmI
  end

  parser.on("token", "Return a bearer token for use in the api") do
    parser.banner = "cb token [-H]"
    action = ->{ puts PROG.token.token }
    parser.on("-H", "Authorization header format") do
      action = ->{ puts "Authorization: Bearer #{PROG.token.token}" }
    end
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
