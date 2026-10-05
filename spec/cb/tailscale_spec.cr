require "../spec_helper"
include CB

Spectator.describe TailscaleConnect do
  subject(action) { described_class.new client: client, output: IO::Memory.new }
  let(client) { Client.new TEST_TOKEN }

  mock_client

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

  it "rejects authkey and client together" do
    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.auth_key = "tskey-abcdef1432341818"
    action.client_id = "n4k7q2m9p3r6s8t1u5v7w9x2y4"

    expect(&.validate).to raise_error Program::Error, /not both/
  end

  it "requires authkey or client" do
    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"

    expect(&.validate).to raise_error Program::Error, /authkey or client/
  end

  it "#run sends auth_key when --authkey is set" do
    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.auth_key = "tskey-abcdef1432341818"

    expect(client).to receive(:put).with(
      "clusters/pkdpq6yynjgjbps4otxd7il2u4/actions/tailscale-connect",
      {"auth_key" => "tskey-abcdef1432341818"},
    ).and_return HTTP::Client::Response.new(200, body: {message: "hi"}.to_json)

    action.call
    expect(action.output.to_s).to contain "hi"
  end

  it "#run sends tailscale_oauth_client_id when --client is set" do
    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.client_id = "n4k7q2m9p3r6s8t1u5v7w9x2y4"

    expect(client).to receive(:put).with(
      "clusters/pkdpq6yynjgjbps4otxd7il2u4/actions/tailscale-connect",
      {"tailscale_oauth_client_id" => "n4k7q2m9p3r6s8t1u5v7w9x2y4"},
    ).and_return HTTP::Client::Response.new(200, body: {message: "hi"}.to_json)

    action.call
  end
end

Spectator.describe Completion do
  it "offers connect --client unless --authkey is already set" do
    client = Client.new TEST_TOKEN
    flags = Completion.parse(client, "cb tailscale connect ")
    expect(flags).to contain "--client\tbridge oauth client id"
    expect(flags).to contain "--authkey\tpre-authentication key"

    with_key = Completion.parse(client, "cb tailscale connect --authkey tskey-example ")
    expect(with_key).to_not contain "--client\tbridge oauth client id"
  end
end

Spectator.describe TailscaleDisconnect do
  subject(action) { described_class.new client: client, output: IO::Memory.new }
  let(client) { Client.new TEST_TOKEN }

  mock_client

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
