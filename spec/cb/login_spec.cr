require "../spec_helper"
include CB

Spectator.describe CB::Login do
  subject(action) { described_class.new input: IO::Memory.new, output: IO::Memory.new }

  describe "#open_browser?" do
    it "return true when input is not 'q'" do
      action.input = IO::Memory.new "y"
      expect(&.open_browser?).to be_true
    end

    it "returns false when input is 'q'" do
      action.input = IO::Memory.new "q"
      expect(&.open_browser?).to be_false
    end
  end

  describe "#call" do
    mock Client
    let(client) { mock(Client) }

    before_each {
      ENV["CB_API_KEY"] = nil
      action.client = client
      action.open_browser = ->(_url : String) { true }
      action.store_credentials = ->(_account : String, _secret : String) { true }
    }

    it "doesn't open browser when input is 'q'" do
      action.input = IO::Memory.new "q"
      expect(&.call).to raise_error
    end

    it "creates and stores a new session" do
      expect(client).to receive(:create_session_intent).and_return(Factory.session_intent)
      expect(client).to receive(:get_account).and_return(Factory.account)
      expect(client).to receive(:get_session_intent).and_return(
        Factory.session_intent(expires_at: Time.utc + 1.day, session: Factory.session)
      )

      action.input = IO::Memory.new "y"

      result = action.call
      expect(result).to_not be_empty
    end

    it "raises error if CB_API_KEY is set" do
      ENV["CB_API_KEY"] = "cbkey_secret"
      expect(&.call).to raise_error(CB::Program::Error)
    end
  end
end
