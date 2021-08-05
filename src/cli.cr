#!/usr/bin/env crystal
require "./cb"
require "option_parser"

PROG = CB::Program.new host: ENV["CB_HOST"]?

class OptionParser
  # for hiding an option from help, omit description
  def on(flag : String, &block : String ->)
    flag, value_type = parse_flag_definition(flag)
    @handlers[flag] = Handler.new(value_type, block)
  end
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

  parser.banner = "Usage: cb [arguments]"

  parser.on("--_completion CMDSTRING") do |cmdstring|
    client = PROG.client rescue nil # in case not logged in
    CB::Completion.parse(client, cmdstring).each { |opt| puts opt }
    exit
  end

  parser.on("login", "Store API key") do
    parser.banner = "Usage: cb login"
    action = ->{ PROG.login }
  end

  parser.on("list", "List clusters") do
    parser.banner = "Usage: cb list"
    action = ->{ PROG.list_clusters }
  end

  parser.on("info", "Detailed cluster information") do
    parser.banner = "Usage: cb info <cluster id>"
    parser.unknown_args do |args|
      id = get_id_arg.call(args)
      action = ->{ PROG.info id }
    end
  end

  parser.on("psql", "Connect to the database using `psql`") do
    parser.banner = "Usage: cb psql <cluster id> [-- [args for psql such as -c or -f]]"
    action = psql = CB::Psql.new(PROG.client)

    parser.unknown_args do |args|
      psql.cluster_id = get_id_arg.call(args)
    end
  end

  parser.on("firewall", "Manage firewall rules") do
    action = manage = CB::ManageFirewall.new(PROG.client)
    parser.banner = "Usage: cb firewall <--cluster> [--add] [--remove]"

    parser.on("--cluster ID", "Choose cluster") { |arg| manage.cluster_id = arg }
    parser.on("--add CIDR", "Add a firewall rule") { |arg| manage.add arg }
    parser.on("--remove CIDR", "Remove a firewall rule") { |arg| manage.remove arg }
  end

  parser.on("create", "Create a new cluster") do
    action = create = CB::ClusterCreate.new(PROG.client)
    parser.banner = <<-EOB
      Usage: cb create <--platform|-p> <--region|-r> <--plan> <--team|-t> [--size|-s] [--name|-n] [--ha] [--network]
             cb create --fork ID [--at] [--platform|-p] [--region|-r] [--plan] [--size|-s] [--name|-n] [--ha] [--network]
             cb create --replica ID [--platform|-p] [--region|-r] [--plan] [--name|-n] [--network]
    EOB

    parser.on("--ha <true|false>", "High Availability (default: false)") { |arg| create.ha = arg }
    parser.on("--plan NAME", "Plan (server vCPU+memory)") { |arg| create.plan = arg }
    parser.on("-n NAME", "--name NAME", "Cluster name (default: Cluster date+time)") { |arg| create.name = arg }
    parser.on("-p NAME", "--platform NAME", "Cloud provider") { |arg| create.platform = arg }
    parser.on("-r NAME", "--region NAME", "Region/Location") { |arg| create.region = arg }
    parser.on("-s GiB", "--storage GiB", "Storage size (default: 100GiB, or same as source)") { |arg| create.storage = arg }
    parser.on("-t ID", "--team ID", "Team") { |arg| create.team = arg }
    parser.on("--network network", "Network") { |arg| create.network = arg }

    parser.on("--replica ID", "Choose source cluster for read-replica") { |arg| create.replica = arg }
    parser.on("--fork ID", "Choose source cluster for fork") { |arg| create.fork = arg }
    parser.on("--at TIME", "Recovery point-in-time in RFC3339 (default: now)") { |arg| create.at = arg }
  end

  parser.on("destroy", "Destroy a cluster") do
    parser.banner = "Usage: cb destroy <cluster id>"
    parser.unknown_args do |args|
      id = get_id_arg.call(args)
      action = ->{ PROG.destroy_cluster id }
    end
  end

  parser.on("scope", "Run diagnostic queries on a cluster") do
    parser.banner = "Usage: cb scope <--cluster> [--(check),...]"
    action = scope = CB::Scope.new PROG.client
    parser.on("--cluster ID", "Choose cluster") { |arg| scope.cluster_id = arg }
    parser.on("--suite <all|quick>", "Run suite of scopes (default: quick)") { |arg| scope.suite = arg }
    Scope::Check.all.each do |ck|
      parser.on(ck.flag, ck.desc) { scope.checks << ck.type }
    end
  end

  parser.on("logdest", "Manage log destinations") do
    parser.banner = "Usage: cb logdest <list|add|destroy>"

    parser.on("list", "List log destinations for a cluster") do
      action = list = CB::LogdestList.new PROG.client
      parser.banner = "Usage: cb logdest list <--cluster>"
      parser.on("--cluster ID", "Choose cluster") { |arg| list.cluster_id = arg }
    end

    parser.on("add", "Add a new log destination to a cluster") do
      action = add = CB::LogdestAdd.new PROG.client
      parser.banner = "Usage: cb logdest add <--cluster> <--host> <--port> <--template> [--desc]"
      parser.on("--cluster ID", "Choose cluster") { |arg| add.cluster_id = arg }
      parser.on("--host HOST", "Hostname") { |arg| add.host = arg }
      parser.on("--port PORT", "Port number") { |arg| add.port = arg }
      parser.on("--template STR", "Log template") { |arg| add.template = arg }
      parser.on("--desc STR", "Description") { |arg| add.desc = arg }
    end

    parser.on("destroy", "Remove an existing log destination from a cluster") do
      action = destroy = CB::LogdestDestroy.new PROG.client
      parser.banner = "Usage: cb logdest destroy <--cluster> <--logdest>"
      parser.on("--cluster ID", "Choose cluster") { |arg| destroy.cluster_id = arg }
      parser.on("--logdest ID", "Choose log destination") { |arg| destroy.logdest_id = arg }
    end
  end

  parser.on("teams", "List teams you belong to") do
    parser.banner = "Usage: cb teams"
    action = ->{ PROG.teams }
  end

  parser.on("teamcert", "Show public TLS cert for a team") do
    parser.banner = "Usage: cb teamcert <team id>"
    parser.unknown_args do |args|
      id = get_id_arg.call(args)
      action = ->{ PROG.team_cert id }
    end
  end

  parser.on("whoami", "Information on current user") do
    action = ->{ puts PROG.creds.id.colorize.t_id }
  end

  parser.on("token", "Return a bearer token for use in the api") do
    parser.banner = "Usage: cb token [-h]"
    action = ->{ puts PROG.token.token }
    parser.on("-H", "Authorization header format") do
      action = ->{ puts "Authorization: Bearer #{PROG.token.token}" }
    end
  end

  parser.on("version", "Show the version") do
    parser.banner = "Usage: cb version"
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
end
