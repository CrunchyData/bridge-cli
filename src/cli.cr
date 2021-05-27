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

begin
  OptionParser.parse do |parser|
    parser.banner = "Usage: cb [arguments]"
    parser.on("--version", "Show the version") do
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

    parser.on("clusters", "list clusters") do
      PROG.clusters
    end

    parser.on("whoami", "information on current user") do
      resp = PROG.client.get "users/info"
    end

    parser.on("info", "detailed cluster information") do
      puts "info"
      parser.unknown_args do |args|
        id = args.first
        PROG.info id
      end
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
rescue e : CB::Program::Error
  print "error: #{e.message}"
  exit 1
end
