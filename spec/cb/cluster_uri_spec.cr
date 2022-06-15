require "../spec_helper"

private class ClusterURITestClient < CB::Client
  ACCOUNT = Account.new(
    id: "123",
    name: "user",
  )

  ROLE = Role.new(
    name: "u_" + ACCOUNT.id,
    password: "secret",
    uri: URI.parse "postgres://u_123:secret@localhost:5432/postgres",
  )

  def get_account
    ACCOUNT
  end

  property p_get_role : Proc(Role) = -> : Role { ROLE }

  def get_role(id, name)
    p_get_role.call
  end
end

describe CB::Action::ClusterURI do
  it "ensures 'default' if role not specified" do
    action = CB::Action::ClusterURI.new(ClusterURITestClient.new(TEST_TOKEN))
    action.output = IO::Memory.new

    action.call

    action.role_name.should eq "default"
  end

  it "#run errors on invalid role" do
    action = CB::Action::ClusterURI.new(ClusterURITestClient.new(TEST_TOKEN))
    action.output = IO::Memory.new

    action.role_name = "invalid"

    msg = /invalid role: 'invalid'/

    expect_cb_error(msg) { action.call }
  end

  it "#run handles client errors" do
    c = ClusterURITestClient.new(TEST_TOKEN)
    c.p_get_role = -> : CB::Client::Role {
      raise CB::Client::Error.new("", "",
        HTTP::Client::Response.new(HTTP::Status::BAD_REQUEST))
    }

    action = CB::Action::ClusterURI.new(c)
    action.output = IO::Memory.new

    msg = /invalid input/

    expect_cb_error(msg) { action.call }
  end

  it "#run prints uri" do
    c = ClusterURITestClient.new(TEST_TOKEN)

    action = CB::Action::ClusterURI.new(c)
    action.output = output = IO::Memory.new

    action.call

    output.to_s.should eq ClusterURITestClient::ROLE.uri.to_s
  end
end
