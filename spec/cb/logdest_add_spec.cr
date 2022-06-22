require "../spec_helper"

private class LogDestinationAddTestClient < CB::Client
end

private def make_lda
  CB::LogDestinationAdd.new(LogDestinationAddTestClient.new(TEST_TOKEN))
end

private def expect_validation_err(lda, part)
  expect_cb_error(/Missing required argument.+#{part}/) { lda.validate }
end

Spectator.describe CB::LogDestinationAdd do
  it "validates that required arguments are present" do
    lda = make_lda

    expect_validation_err lda, "cluster"
    lda.cluster_id = "afpvoqooxzdrriu6w3bhqo55c4"
    expect_validation_err lda, "port"
    lda.port = 2345
    expect_validation_err lda, "desc"
    lda.description = "hello"
    expect_validation_err lda, "host"
    lda.host = "example.com"
    expect_validation_err lda, "template"
    lda.template = "some stuff"
    lda.validate.should eq true
  end

  it "only allows valid eids for cluster arg" do
    lda = make_lda
    lda.cluster_id = "afpvoqooxzdrriu6w3bhqo55c4"
    expect_cb_error(/cluster id/) { lda.cluster_id = "notaneid" }
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
