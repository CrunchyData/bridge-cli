require "../spec_helper"

private class LogDestinationUpdateTestClient < CB::Client
end

private class LogDestinationUpdateTrackingClient < CB::Client
  getter body_sent : Hash(String, String | Int32 | Bool)?

  def initialize(@list_rows : Array(CB::Model::LogDestination), token : String = TEST_TOKEN)
    super(host: CB::HOST, bearer_token: token)
  end

  def get_log_destinations(cluster_id)
    @list_rows
  end

  def update_log_destination(cluster_id, logdest_id, body)
    @body_sent = body
    "{}"
  end
end

private def make_ldu
  CB::LogDestinationUpdate.new(LogDestinationUpdateTestClient.new(TEST_TOKEN))
end

Spectator.describe CB::LogDestinationUpdate do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(cluster) { Factory.cluster }
  let(logdest) { Factory.log_destination }

  it "ensures required arguments are present" do
    expect_missing_arg_error
    action.cluster_id = cluster.id

    expect_missing_arg_error
    action.logdest_id = logdest.id

    expect(&.validate).to be_true
  end

  it "sets a default description based on the host if missing" do
    ldu = make_ldu
    ldu.description.should be_nil

    ldu.host = "foo"
    ldu.host.should eq "foo"
    ldu.description.should eq "foo"

    ldu.description = nil
    ldu.host = "bar.com"
    ldu.description.should eq "bar"

    ldu.description = nil
    ldu.host = "logs.baz.com"
    ldu.description.should eq "baz"

    ldu.description = "already set dont change"
    ldu.host = "logs.zam.com"
    ldu.description.should eq "already set dont change"
  end

  it "rejects invalid boolean strings for optional tls flag" do
    ldu = make_ldu
    expect { ldu.tls_verify_disabled = "maybe" }.to raise_error(CB::Program::Error, /Invalid/)
  end

  it "rejects invalid boolean strings for optional forward-connection flag" do
    ldu = make_ldu
    expect { ldu.forward_connection_logs = "on" }.to raise_error(CB::Program::Error, /Invalid/)
  end

  describe "#run" do
    let(row) { Factory.log_destination }

    it "fills host, port, template, and description from list when omitted" do
      tracking = LogDestinationUpdateTrackingClient.new([row])
      act = CB::LogDestinationUpdate.new(client: tracking, output: IO::Memory.new)
      act.cluster_id = cluster.id
      act.logdest_id = row.id
      act.call
      tracking.body_sent.should eq({
        "host"                      => "host",
        "port"                      => 2020,
        "template"                  => "template",
        "description"               => "logdest descr",
        "tls_verify_disabled"       => false,
        "forward_connection_logs"   => false,
      })
    end

    it "merges optional flags with list defaults" do
      tracking = LogDestinationUpdateTrackingClient.new([row])
      act = CB::LogDestinationUpdate.new(client: tracking, output: IO::Memory.new)
      act.cluster_id = cluster.id
      act.logdest_id = row.id
      act.forward_connection_logs = true
      act.call
      tracking.body_sent.should eq({
        "host"                      => "host",
        "port"                      => 2020,
        "template"                  => "template",
        "description"               => "logdest descr",
        "tls_verify_disabled"       => false,
        "forward_connection_logs"   => true,
      })
    end

    it "keeps the other boolean from the list when only one flag is set" do
      row_with_flags = Factory.log_destination(
        tls_verify_disabled: true,
        forward_connection_logs: false,
      )
      tracking = LogDestinationUpdateTrackingClient.new([row_with_flags])
      act = CB::LogDestinationUpdate.new(client: tracking, output: IO::Memory.new)
      act.cluster_id = cluster.id
      act.logdest_id = row_with_flags.id
      act.forward_connection_logs = true
      act.call
      tracking.body_sent.try &.["tls_verify_disabled"].should eq true
      tracking.body_sent.try &.["forward_connection_logs"].should eq true
    end

    it "applies tls_verify_disabled from a string argument" do
      row_with_flags = Factory.log_destination(
        tls_verify_disabled: true,
        forward_connection_logs: true,
      )
      tracking = LogDestinationUpdateTrackingClient.new([row_with_flags])
      act = CB::LogDestinationUpdate.new(client: tracking, output: IO::Memory.new)
      act.cluster_id = cluster.id
      act.logdest_id = row_with_flags.id
      act.tls_verify_disabled = "false"
      act.call
      tracking.body_sent.try &.["tls_verify_disabled"].should eq false
      tracking.body_sent.try &.["forward_connection_logs"].should eq true
    end

    it "applies forward_connection_logs from a string argument" do
      row_with_flags = Factory.log_destination(
        tls_verify_disabled: false,
        forward_connection_logs: true,
      )
      tracking = LogDestinationUpdateTrackingClient.new([row_with_flags])
      act = CB::LogDestinationUpdate.new(client: tracking, output: IO::Memory.new)
      act.cluster_id = cluster.id
      act.logdest_id = row_with_flags.id
      act.forward_connection_logs = "false"
      act.call
      tracking.body_sent.try &.["tls_verify_disabled"].should eq false
      tracking.body_sent.try &.["forward_connection_logs"].should eq false
    end

    it "overrides port from the list when given" do
      tracking = LogDestinationUpdateTrackingClient.new([row])
      act = CB::LogDestinationUpdate.new(client: tracking, output: IO::Memory.new)
      act.cluster_id = cluster.id
      act.logdest_id = row.id
      act.port = 9999
      act.call
      tracking.body_sent.try &.["port"].should eq 9999
      tracking.body_sent.try &.["host"].should eq "host"
    end

    it "raises when the log destination is not on the list" do
      tracking = LogDestinationUpdateTrackingClient.new([] of CB::Model::LogDestination)
      act = CB::LogDestinationUpdate.new(client: tracking, output: IO::Memory.new)
      act.cluster_id = cluster.id
      act.logdest_id = row.id
      expect_raises(CB::Program::Error, /not found/) { act.call }
    end

    it "raises when the list has no matching log destination id" do
      other = Factory.log_destination(
        id: "pkdpq6yynjgjbps4otxd7il2u4",
      )
      tracking = LogDestinationUpdateTrackingClient.new([other])
      act = CB::LogDestinationUpdate.new(client: tracking, output: IO::Memory.new)
      act.cluster_id = cluster.id
      act.logdest_id = row.id
      expect_raises(CB::Program::Error, /not found/) { act.call }
    end
  end
end
