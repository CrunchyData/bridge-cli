require "../spec_helper"

private class LogdestAddTestClient < CB::Client
end

private def make_lda
  CB::LogdestAdd.new(LogdestAddTestClient.new(TEST_TOKEN))
end

private def expect_validation_err(lda, part)
  expect_cb_error(/Missing required argument.+#{part}/) { lda.validate }
end

describe CB::LogdestAdd do
  it "validates that required arguments are present" do
    lda = make_lda

    expect_validation_err lda, "cluster"
    lda.cluster_id = "afpvoqooxzdrriu6w3bhqo55c4"
    expect_validation_err lda, "port"
    lda.port = 2345
    expect_validation_err lda, "desc"
    lda.desc = "hello"
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
    lda.desc.should be_nil

    lda.host = "foo"
    lda.host.should eq "foo"
    lda.desc.should eq "foo"

    lda.desc = nil
    lda.host = "bar.com"
    lda.desc.should eq "bar"

    lda.desc = nil
    lda.host = "logs.baz.com"
    lda.desc.should eq "baz"

    lda.desc = "already set dont change"
    lda.host = "logs.zam.com"
    lda.desc.should eq "already set dont change"
  end
end
