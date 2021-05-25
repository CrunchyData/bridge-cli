#!/usr/bin/env crystal
require "./cb"
require "option_parser"

PROG = CB::Program.new

begin
  OptionParser.parse do |parser|
    parser.banner = "Usage: cb [arguments]"
    parser.on("--version", "Show the version") do
      puts "cb v#{CB::VERSION}"
      exit
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
