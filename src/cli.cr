#!/usr/bin/env crystal
require "./cb"
require "option_parser"

PROG = CB::Program.new

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
      puts parser
      exit 1
    end
    args.first
  end

  parser.banner = "Usage: cb [arguments]"
  parser.on("version", "Show the version") do
    parser.banner = "Usage: cb version"
    puts "cb v#{CB::VERSION}"
    exit
  end

  parser.on("--_completion CMDSTRING") do |cmdstring|
    CB::Completion.parse(PROG.client, cmdstring).each { |opt| puts opt }
  end

  parser.on("login", "Store API key") do
    parser.banner = "Usage: cb login"
    action = ->{ PROG.login }
  end

  parser.on("token", "return a bearar token for use in the api") do
    parser.banner = "Usage: cb token"
    action = ->{ puts PROG.token.token }
  end

  parser.on("teams", "list teams you belong to") do
    parser.banner = "Usage: cb teams"
    action = ->{ PROG.teams }
  end

  parser.on("list", "list clusters") do
    parser.banner = "Usage: cb list"
    action = ->{ PROG.list_clusters }
  end

  parser.on("whoami", "information on current user") do
    action = ->{ PROG.client.get "users/info" }
  end

  parser.on("info", "detailed cluster information") do
    parser.banner = "Usage: cb info <cluster id>"
    parser.unknown_args do |args|
      id = get_id_arg.call(args)
      action = ->{ PROG.info id }
    end
  end

  parser.on("firewall", "manage firewall rules") do
    action = manage = CB::ManageFirewall.new(PROG.client)
    parser.banner = "Usage: cb firewall <--cluster> [--add] [--remove]"

    parser.on("--cluster ID", "choose cluster") { |arg| manage.cluster_id = arg }
    parser.on("--add CIDR", "add a firewall rule") { |arg| manage.add arg }
    parser.on("--remove CIDR", "remove a firewall rule") { |arg| manage.remove arg }
  end

  parser.on("destroy", "destroy a cluster") do
    parser.banner = "Usage: cb destroy <cluster id>"
    parser.unknown_args do |args|
      id = get_id_arg.call(args)
      action = ->{ PROG.destroy_cluster id }
    end
  end

  parser.on("create", "create a new cluster") do
    action = create = CB::CreateCluster.new(PROG.client)
    parser.banner = "Usage: cb create <--platform|-p> <--region|-r> <--plan> <--team|-t> [--size|-s] [--name|-n] [--ha]"

    parser.on("--ha <true|false>", "High Availability (default: false)") { |arg| create.ha = arg }
    parser.on("--plan NAME", "Plan (server vCPU+memory)") { |arg| create.plan = arg }
    parser.on("-n NAME", "--name NAME", "Cluster name (default: Cluster date+time)") { |arg| create.name = arg }
    parser.on("-p NAME", "--platform NAME", "Cloud provider") { |arg| create.platform = arg }
    parser.on("-r NAME", "--region NAME", "Region/Location") { |arg| create.region = arg }
    parser.on("-s GiB", "--storage GiB", "Storage size (default: 100GiB)") { |arg| create.storage = arg }
    parser.on("-t ID", "--team ID", "Team") { |arg| create.team = arg }
  end

  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end

  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option."
    STDERR.puts parser
    exit(1)
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
      STDERR << "error".colorize.t_warn << ": Token expired, but has been refreshed. Please try again.\n"
      exit 1
    end
  end
  STDERR.puts e
  exit 2
end
