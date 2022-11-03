require "../spec_helper"
include CB

Spectator.describe TailscaleConnect do
  subject(action) { described_class.new client: client, output: IO::Memory.new }
  let(client) { Client.new TEST_TOKEN }

  mock Client do
    stub put(path, body)
  end

  it "validates that required arguments are present" do
    expect(&.validate).to raise_error Program::Error, /Missing required argument/

    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.auth_key = "tskey-abcdef1432341818"

    expect(&.validate).to be_true
  end

  it "#run makes an api call" do
    action.output = IO::Memory.new
    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.auth_key = "tskey-abcdef1432341818"

    expect(client).to receive(:put).and_return HTTP::Client::Response.new(200, body: {message: "hi"}.to_json)

    action.call
  end
end

Spectator.describe TailscaleDisconnect do
  subject(action) { described_class.new client: client, output: IO::Memory.new }
  let(client) { Client.new TEST_TOKEN }

  mock Client do
    stub put(path, body = nil) # ameba:disable Lint/UselessAssign
  end

  it "validates that required arguments are present" do
    expect(&.validate).to raise_error Program::Error, /Missing required argument/

    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"

    expect(&.validate).to be_true
  end

  it "#run makes an api call" do
    action.output = IO::Memory.new
    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"

    expect(client).to receive(:put).and_return HTTP::Client::Response.new(200, body: {message: "hi"}.to_json)

    action.call
  end
end
