require "../spec_helper"

# This file intentionally does not use `mock_client`: Spectator's Client mock
# is injected into CB::Client and prevents subclasses from overriding API methods.

private class LogDestinationAddCaptureClient < CB::Client
  getter last_cluster_id : String?
  getter last_payload_json : String = ""

  def initialize(token : String = TEST_TOKEN)
    super(host: CB::HOST, bearer_token: token)
  end

  def add_log_destination(cluster_id, ld)
    @last_cluster_id = cluster_id.to_s
    @last_payload_json = ld.to_json
    "{}"
  end
end

Spectator.describe "CB::LogDestinationAdd API payload" do
  let(cluster) { Factory.cluster }

  it "sends tls and forward-connection flags in the create payload" do
    cap = LogDestinationAddCaptureClient.new
    act = CB::LogDestinationAdd.new(client: cap, output: IO::Memory.new)
    act.cluster_id = cluster.id
    act.port = 514
    act.description = "d"
    act.host = "logs.example.com"
    act.template = "jsonline"
    act.tls_verify_disabled = "true"
    act.forward_connection_logs = "false"
    act.call
    cap.last_cluster_id.should eq cluster.id
    j = JSON.parse(cap.last_payload_json).as_h
    j["host"].as_s.should eq "logs.example.com"
    j["port"].as_i.should eq 514
    j["template"].as_s.should eq "jsonline"
    j["description"].as_s.should eq "d"
    j["tls_verify_disabled"].as_bool.should be_true
    j["forward_connection_logs"].as_bool.should be_false
  end

  it "defaults tls and forward-connection to false in the payload when unset" do
    cap = LogDestinationAddCaptureClient.new
    act = CB::LogDestinationAdd.new(client: cap, output: IO::Memory.new)
    act.cluster_id = cluster.id
    act.port = 514
    act.description = "d"
    act.host = "logs.example.com"
    act.template = "jsonline"
    act.call
    j = JSON.parse(cap.last_payload_json).as_h
    j["tls_verify_disabled"].as_bool.should be_false
    j["forward_connection_logs"].as_bool.should be_false
  end
end
