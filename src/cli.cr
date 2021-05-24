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
  end
rescue e : CB::Program::Error
  print "error: #{e.message}"
  exit 1
end
