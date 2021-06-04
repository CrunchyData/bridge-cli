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
  parser.banner = "Usage: cb [arguments]"
  parser.on("version", "Show the version") do
    puts "cb v#{CB::VERSION}"
    exit
  end

  parser.on("--_completion CMDSTRING") do |cmdstring|
    CB::Completion.parse(PROG.client, cmdstring).each { |opt| puts opt }
  end

  parser.on("login", "Store API key") do
    PROG.login
  end

  parser.on("token", "return a bearar token for use in the api") do
    puts PROG.token.token
  end

  parser.on("teams", "list teams you belong to") do
    PROG.teams
  end

  parser.on("list", "list clusters") do
    PROG.list_clusters
  end

  parser.on("whoami", "information on current user") do
    PROG.client.get "users/info"
  end

  parser.on("info", "detailed cluster information") do
    parser.unknown_args do |args|
      id = args.first
      PROG.info id
    end
  end

  parser.on("destroy", "destroy a cluster") do
    parser.unknown_args do |args|
      id = args.first
      PROG.destroy_cluster id
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
  action.try &.run
rescue e : CB::Program::Error
  STDERR.puts "#{"error".colorize.red.bold}: #{e.message}"
  STDERR.puts op if e.show_usage

  exit 1
rescue e : CB::Client::Error
  STDERR.puts "#{"error".colorize.red.bold}: #{e.resp.status.code.colorize.cyan} #{e.resp.status.description.colorize.red}"
  indent = "       "
  STDERR.puts "#{indent}#{e.method.upcase.colorize.green} to /#{e.path.colorize.green}"

  begin
    JSON.parse(e.resp.body).as_h.each do |k, v|
      STDERR.puts "#{indent}#{"#{k}:".colorize.light_cyan} #{v}"
    end
  rescue JSON::ParseException
    STDERR.puts "#{indent}#{e.resp.body}"
  end

  exit 2
end
