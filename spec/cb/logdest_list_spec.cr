require "../spec_helper"

private class TtyMemory < IO::Memory
  def tty?
    true
  end
end

private class LogDestinationListTestClient < CB::Client
  getter last_cluster : String?

  def get_log_destinations(cluster_id)
    @last_cluster = cluster_id
    [
      Factory.log_destination(
        tls_verify_disabled: true,
        forward_connection_logs: false,
      ),
      Factory.log_destination(
        id: "pkdpq6yynjgjbps4otxd7il2u4",
        description: "second",
        tls_verify_disabled: false,
        forward_connection_logs: true,
      ),
    ]
  end
end

private class LogDestinationListEmptyClient < CB::Client
  def initialize(token : String = TEST_TOKEN)
    super(host: CB::HOST, bearer_token: token)
  end

  def get_log_destinations(cluster_id)
    [] of CB::Model::LogDestination
  end
end

Spectator.describe CB::LogDestinationList do
  let(client) { LogDestinationListTestClient.new(TEST_TOKEN) }
  let(cluster) { Factory.cluster }
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  it "lists flags on tty" do
    io = TtyMemory.new
    act = CB::LogDestinationList.new(client: client, output: io)
    act.cluster_id = cluster.id
    act.call
    s = io.to_s
    s.should contain("TLS verify disabled: yes")
    s.should contain("Forward connection logs: no")
    s.should contain("TLS verify disabled: no")
    s.should contain("Forward connection logs: yes")
    client.last_cluster.should eq cluster.id
  end

  it "appends flag columns when piped" do
    act = CB::LogDestinationList.new(client: client, output: IO::Memory.new)
    act.cluster_id = cluster.id
    act.call
    lines = act.output.to_s.lines.map(&.rstrip("\n"))
    lines.size.should eq 2
    lines[0].split('\t').size.should eq 7
    lines[0].ends_with?("\ttrue\tfalse").should be_true
    lines[1].ends_with?("\tfalse\ttrue").should be_true
  end

  it "prints a message when there are no log destinations" do
    io = TtyMemory.new
    act = CB::LogDestinationList.new(client: LogDestinationListEmptyClient.new(TEST_TOKEN), output: io)
    act.cluster_id = Factory.cluster.id
    act.call
    io.to_s.should contain("no log destinations")
  end
end
