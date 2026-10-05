require "../spec_helper"
include CB

TEAM_ID   = "p5jflp7w3zhe7bu7c4s2t4e2wq"
CLIENT_ID = "pkdpq6yynjgjbps4otxd7il2u4"

def oauth_client
  Model::TailscaleOAuthClient.new(
    id: CLIENT_ID,
    name: "production",
    team_id: TEAM_ID,
  )
end

Spectator.describe TailscaleClientCreate do
  subject(action) { described_class.new client: client, output: IO::Memory.new }
  let(client) { Client.new TEST_TOKEN }

  mock_client

  it "validates that required arguments are present" do
    expect(&.validate).to raise_error Program::Error, /Missing required argument/
  end

  it "#run sends the create fields and prints the Bridge id" do
    action.team_id = TEAM_ID
    action.name = "production"
    action.tailscale_client_id = "k123456CNTRL"
    action.tailscale_client_secret = "tskey-client-example"
    action.tags << "tag:production"
    action.tags << "tag:other"

    expect(client).to receive(:create_tailscale_oauth_client).with(
      TEAM_ID,
      client_id: "k123456CNTRL",
      client_secret: "tskey-client-example",
      name: "production",
      tags: ["tag:production", "tag:other"],
    ).and_return(oauth_client)

    action.call

    printed = action.output.to_s
    expect(printed).to contain CLIENT_ID
    expect(printed).to contain TEAM_ID
    expect(printed).to contain "production"
    expect(printed).to_not contain "tskey-client-example"
  end
end

Spectator.describe TailscaleClientList do
  subject(action) { described_class.new client: client, output: IO::Memory.new }
  let(client) { Client.new TEST_TOKEN }

  mock_client

  it "validates that team is present" do
    expect(&.validate).to raise_error Program::Error, /Missing required argument/
  end

  it "#run prints a table of id, team, and name" do
    action.team_id = TEAM_ID
    expect(client).to receive(:get_tailscale_oauth_clients).with(TEAM_ID).and_return([oauth_client])

    action.call

    printed = action.output.to_s
    expect(printed).to contain "ID"
    expect(printed).to contain CLIENT_ID
    expect(printed).to contain TEAM_ID
    expect(printed).to contain "production"
  end

  it "#run can omit the table header" do
    action.team_id = TEAM_ID
    action.no_header = true
    expect(client).to receive(:get_tailscale_oauth_clients).with(TEAM_ID).and_return([oauth_client])

    action.call

    expect(action.output.to_s).to_not contain "ID"
    expect(action.output.to_s).to contain CLIENT_ID
  end

  it "#run can print json" do
    action.team_id = TEAM_ID
    action.format = "json"
    expect(client).to receive(:get_tailscale_oauth_clients).with(TEAM_ID).and_return([oauth_client])

    action.call

    payload = JSON.parse(action.output.to_s)
    expect(payload["clients"][0]["id"]).to eq CLIENT_ID
    expect(payload["clients"][0]["team_id"]).to eq TEAM_ID
    expect(payload["clients"][0]["name"]).to eq "production"
    expect(payload["clients"][0]["client_secret"]?).to be_nil
  end
end

Spectator.describe TailscaleClientDestroy do
  subject(action) { described_class.new client: client, output: IO::Memory.new }
  let(client) { Client.new TEST_TOKEN }

  mock_client

  it "validates that team and client are present" do
    action.team_id = TEAM_ID
    expect(&.validate).to raise_error Program::Error, /Missing required argument/
  end

  it "#run deletes by team and Bridge client id" do
    action.team_id = TEAM_ID
    action.client_id = CLIENT_ID
    expect(client).to receive(:destroy_tailscale_oauth_client).with(TEAM_ID, CLIENT_ID).and_return(oauth_client)

    action.call

    expect(action.output.to_s).to contain CLIENT_ID
    expect(action.output.to_s).to contain "production"
  end
end

Spectator.describe Completion do
  it "suggests tailscale client commands and create flags" do
    client = Client.new TEST_TOKEN

    commands = Completion.parse(client, "cb tailscale ")
    expect(commands).to contain "client\tmanage tailscale oauth clients"

    subcommands = Completion.parse(client, "cb tailscale client ")
    expect(subcommands).to contain "create\tregister a tailscale oauth client"
    expect(subcommands).to contain "list\tlist tailscale oauth clients"
    expect(subcommands).to contain "destroy\tremove a tailscale oauth client"

    flags = Completion.parse(client, "cb tailscale client create ")
    expect(flags).to contain "--team\tchoose team"
    expect(flags).to contain "--tailscale-client-id\tclient id from tailscale"
    expect(flags).to contain "--tag\tacl tag"

    after_id = Completion.parse(client, "cb tailscale client create --tailscale-client-id k123 ")
    expect(after_id).to_not contain "--tailscale-client-id\tclient id from tailscale"
    expect(after_id).to contain "--tag\tacl tag"
  end
end
