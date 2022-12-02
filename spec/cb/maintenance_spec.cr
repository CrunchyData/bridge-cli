require "../spec_helper"
include CB

Spectator.describe MaintenanceUpdate do
  subject(action) { described_class.new client: client, output: IO::Memory.new }
  let(client) { Client.new TEST_TOKEN }

  mock_client

  it "validates that required arguments are present" do
    expect(&.validate).to raise_error Program::Error, /Missing required argument: cluster/

    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"

    expect(&.validate).to raise_error Program::Error, /Missing required argument: window-start/

    expect { action.window_start = "windows should not be a string" }.to raise_error Program::Error, /Invalid window_start/

    action.window_start = 14
    expect(&.validate).to be_true
  end

  it "rejects if both unset and window-start are present" do
    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.window_start = 14
    action.unset = true
    expect(&.validate).to raise_error Program::Error, /Must use '--window-start' or '--unset'/
  end

  it "rejects invalid window-start " do
    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"

    action.window_start = -1
    expect(&.validate).to raise_error Program::Error, /'--window-start' should be between 0 and 23/

    action.window_start = 24
    expect(&.validate).to raise_error Program::Error, /'--window-start' should be between 0 and 23/
  end

  it "#run makes an api call" do
    action.output = IO::Memory.new
    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.window_start = 14

    updated_cluster = Factory.cluster(maintenance_window_start: 14)

    expect(client).to receive(:update_cluster).with(action.cluster_id[:cluster], {"maintenance_window_start" => 14}).and_return updated_cluster

    action.call

    expect(&.output.to_s).to match /updated to 14:00/
  end

  it "#run with unset removed the maintenance window" do
    action.output = IO::Memory.new
    action.cluster_id = "pkdpq6yynjgjbps4otxd7il2u4"
    action.unset = true

    updated_cluster = Factory.cluster

    expect(client).to receive(:update_cluster).with(action.cluster_id[:cluster], {"maintenance_window_start" => -1}).and_return updated_cluster

    action.call

    expect(&.output.to_s).to match /updated to no window set. Default to: 00:00-23:59/
  end
end
