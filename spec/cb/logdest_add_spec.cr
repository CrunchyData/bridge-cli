require "../spec_helper"

private class LogDestinationAddTestClient < CB::Client
end

private def make_lda
  CB::LogDestinationAdd.new(LogDestinationAddTestClient.new(TEST_TOKEN))
end

Spectator.describe CB::LogDestinationAdd do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  mock_client

  let(cluster) { Factory.cluster }

  it "ensures required arguments are present" do
    expect_missing_arg_error
    action.cluster_id = cluster.id

    expect_missing_arg_error
    action.port = 2345

    expect_missing_arg_error
    action.description = "hello"

    expect_missing_arg_error
    action.host = "example.com"

    expect_missing_arg_error
    action.template = "some stuff"

    expect(&.validate).to be_true
  end

  it "sets a default description based on the host if missing" do
    lda = make_lda
    lda.description.should be_nil

    lda.host = "foo"
    lda.host.should eq "foo"
    lda.description.should eq "foo"

    lda.description = nil
    lda.host = "bar.com"
    lda.description.should eq "bar"

    lda.description = nil
    lda.host = "logs.baz.com"
    lda.description.should eq "baz"

    lda.description = "already set dont change"
    lda.host = "logs.zam.com"
    lda.description.should eq "already set dont change"
  end

  it "accepts tls and connection log flags as true or false strings" do
    lda = make_lda
    lda.tls_verify_disabled = "true"
    lda.tls_verify_disabled.should be_true
    lda.tls_verify_disabled = "false"
    lda.tls_verify_disabled.should be_false
    lda.forward_connection_logs = "TRUE"
    lda.forward_connection_logs.should be_true
    lda.forward_connection_logs = "false"
    lda.forward_connection_logs.should be_false
  end

  it "rejects invalid boolean strings for tls_verify_disabled" do
    lda = make_lda
    expect { lda.tls_verify_disabled = "yes" }.to raise_error(CB::Program::Error, /Invalid/)
  end

  it "rejects invalid boolean strings for forward_connection_logs" do
    lda = make_lda
    expect { lda.forward_connection_logs = "1" }.to raise_error(CB::Program::Error, /Invalid/)
  end
end
