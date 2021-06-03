require "spec"
require "../src/cb"

Colorize.enabled = false
TEST_TOKEN = CB::Token.new("localhost", "token", Time.local.to_unix + 1.hour.seconds)
