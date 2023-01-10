require "../spec_helper"
include CB

Spectator.describe CB::Open do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  let(client_host) { "api.crunchybridge.com" }
  let(session_id) { "af73g4rdcuyo3ol766fkmtfb3y" }
  let(session_one_time_token) { "cbott_one_time_token_secret" }

  mock_client

  describe ".open_command" do
    it "successfully returns the name of an executable" do
      expect(action.class.open_command).to_not be_nil
    end
  end

  describe "#call" do
    before_each do
      client.host = client_host
    end

    it "creates a session and executes open" do
      open_args : Array(String)? = nil

      action.open = ->(args : Array(String), _env : Process::Env) do
        open_args = args
        nil
      end

      expect(client).to receive(:create_session)
        .with(
          Client::SessionCreateParams.new(generate_one_time_token: true)
        )
        .and_return(
          Client::Session.new(id: session_id, one_time_token: session_one_time_token)
        )

      action.call

      expected_login_url = "https://#{client_host}/sessions/#{session_id}/actions/login?one_time_token=#{session_one_time_token}"
      expect(open_args).to eq([expected_login_url])
    end
  end
end
