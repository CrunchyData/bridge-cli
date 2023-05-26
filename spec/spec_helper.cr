require "../src/cb"
require "./factory"
# require "spec"
require "spectator"
require "spectator/should"

include CB

Colorize.enabled = false
TEST_TOKEN = "cbkey_secret"

macro expect_cb_error(message)
  expect({{ yield }}).to raise_error(CB::Program::Error, {{message}})
end

macro expect_missing_arg_error
  expect(&.validate).to raise_error(CB::Program::Error, /Missing required argument/)
end

macro expect_invalid_arg_error
  expect({{yield}}).to raise_error(CB::Program::Error, /Invalid/)
end

macro mock_client
  mock Client do
    def initialize(@token : Token = TEST_TOKEN)
    end

    {{ yield }}
  end

  let(client) { mock(Client) }
end

def invalid_ids
  [
    "yes",
    "afpvoqooxzdrriu6w3bhqo55c3",
    "aafpvoqooxzdrriu6w3bhqo55c4",
    "fpvoqooxzdrriu6w3bhqo55c4",
  ]
end
