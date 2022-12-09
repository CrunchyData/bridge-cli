require "../spec_helper"
include CB

Spectator.describe CB::Open do
  subject(action) { described_class.new client: client, output: IO::Memory.new }

  let(client_host) { "api.crunchybridge.com" }
  let(session_id) { "af73g4rdcuyo3ol766fkmtfb3y" }
  let(session_one_time_token) { "cbott_one_time_token_secret" }

  mock_client

  describe "#call" do
    before_each do
      client.host = client_host
    end

    it "creates a session and executes open" do
      ENV["CB_API_KEY"] = nil

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
          CB::Model::Session.new(id: session_id, one_time_token: session_one_time_token)
        )

      action.call

      expected_login_url = "https://#{client_host}/sessions/#{session_id}/actions/login?one_time_token=#{session_one_time_token}"
      expect(open_args).to eq([expected_login_url])
    end

    it "raises error if CB_API_KEY set" do
      ENV["CB_API_KEY"] = "cbkey_secret"
      expect(&.call).to raise_error(CB::Program::Error)
    end
  end
end
