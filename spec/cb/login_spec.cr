require "../spec_helper"
include CB

Spectator.describe CB::Login do
  subject(action) { described_class.new input: IO::Memory.new, output: IO::Memory.new }

  describe "#call" do
    mock Client
    let(client) { mock(Client) }

    mock CB::Lib::Open
    let(lib_open_mock) { class_mock(CB::Lib::Open) }

    mock Process
    let(process_mock) { class_mock(Process) }

    let(account) { Factory.account }

    before_each {
      ENV["CB_API_KEY"] = nil
      action.client = client
      action.store_credentials = ->(_account : String, _secret : String) { true }
      action.lib_open = lib_open_mock
    }

    it "creates and stores a new session (browser)" do
      expect(lib_open_mock).to receive(:can_open_browser?).and_return(true)
      expect(lib_open_mock).to receive(:run).and_return(true)
      expect(client).to receive(:create_session_intent).and_return(Factory.session_intent)
      expect(client).to receive(:get_account).and_return(account)
      expect(client).to receive(:get_session_intent).and_return(
        Factory.session_intent(expires_at: Time.utc + 1.day, session: Factory.session)
      )

      action.input = IO::Memory.new "\n"

      result = action.call
      expect(result).to_not be_empty
      expect(action.output.to_s.ends_with?("Logged in as #{account.email}\n")).to be_true
    end

    it "creates and stores a new session (headless)" do
      expect(lib_open_mock).to receive(:can_open_browser?).and_return(false)
      expect(client).to receive(:create_session_intent).and_return(Factory.session_intent)
      expect(client).to receive(:get_account).and_return(account)
      expect(client).to receive(:get_session_intent).and_return(
        Factory.session_intent(expires_at: Time.utc + 1.day, session: Factory.session)
      )

      result = action.call
      expect(result).to_not be_empty
      expect(action.output.to_s.ends_with?("Logged in as #{account.email}\n")).to be_true
    end

    # it "exits with error message if session is expired" do
    #   expect(lib_open_mock).to receive(:can_open_browser?).and_return(false)
    #   expect(client).to receive(:get_session_intent).and_return(
    #     Factory.session_intent(expires_at: Time.utc - 1.day, session: Factory.session)
    #   )

    #   action.call

    #   expect(action.output.to_s.ends_with?("login error: login timed out\n")).to be_true
    # end

    it "raises error if CB_API_KEY is set" do
      ENV["CB_API_KEY"] = "cbkey_secret"
      expect(&.call).to raise_error(CB::Program::Error)
    end
  end
end
