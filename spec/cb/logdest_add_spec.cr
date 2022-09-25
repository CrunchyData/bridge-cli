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
end
