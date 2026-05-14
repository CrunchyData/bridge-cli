require "../spec_helper"

Spectator.describe CB::Model::LogDestination do
  it "parses tls flags from list JSON" do
    json = %({"loggers":[{"id":"pxbcigcufjdqje6drled4rj6p4","host":"h","port":1,"template":"t","description":"d","tls_verify_disabled":true,"forward_connection_logs":false}]})
    list = Array(CB::Model::LogDestination).from_json json, root: "loggers"
    list.size.should eq 1
    d = list.first
    d.tls_verify_disabled.should be_true
    d.forward_connection_logs.should be_false
  end

  it "defaults tls flags when keys are missing" do
    json = %({"loggers":[{"id":"pxbcigcufjdqje6drled4rj6p4","host":"h","port":1,"template":"t","description":"d"}]})
    d = Array(CB::Model::LogDestination).from_json(json, root: "loggers").first
    d.tls_verify_disabled.should be_false
    d.forward_connection_logs.should be_false
  end
end
