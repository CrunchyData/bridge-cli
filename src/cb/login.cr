require "retriable"
require "./action"

module CB
  class Login < Action
    private class NoSession < Exception
      def initialize(message = "No session")
        super(message)
      end
    end

    property open_browser : Proc(String, Bool) = ->(url : String) : Bool {
      CB::Lib::Open.run([url])
    }

    property store_credentials : Proc(String, String, Bool) = ->(account : String, secret : String) : Bool {
      Credentials.store account: account, secret: secret
    }

    property client : CB::Client = CB::Client.new CB::HOST

    def open_browser? : Bool
      output << "Press any key to open a browser to login or "
      output << "q".colorize.yellow
      output << " to exit: "

      response = if input == STDIN
                   STDIN.raw &.read_char
                 else
                   input.read_char
                 end
      output << '\n'

      return response.downcase != 'q' if response
      false
    end

    def run
      # Prevent login if API key ENV is set.
      raise Error.new "Cannot login with #{"CB_API_KEY".colorize.red.bold} set." if ENV["CB_API_KEY"]?

      # Prompt to open a browser or allow the user to abort the login.
      raise Error.new "Aborting login." unless open_browser?

      # Request a session intent.
      si_params = Client::SessionIntentCreateParams.new(agent_name: "cb #{CB::VERSION}")
      session_intent = @client.create_session_intent si_params

      # Open a browser with the new session intent.
      login_url = "https://www.crunchybridge.com/account/verify-cli/#{session_intent.id}?code=#{session_intent.code}"
      @open_browser.call(login_url)

      # Begin polling for session intent activation.
      spinner = Spinner.new("Waiting for login...", output)
      spinner.start

      si_get_params = Client::SessionIntentGetParams.new(
        session_intent_id: session_intent.id,
        secret: "#{session_intent.secret}",
      )

      begin
        Retriable.retry(on: NoSession, base_interval: 1.seconds, multiplier: 1.0, rand_factor: 0.0) do
          session_intent = @client.get_session_intent(si_get_params)
          raise Error.new "login timed out" if Time.utc > session_intent.expires_at
          raise NoSession.new unless session_intent.session
        end

        spinner.stop

        secret = session_intent.session.try &.secret
        account = @client.get_account(secret)
      rescue e : CB::Client::Error
        output << '\n'
        raise Error.new e.resp.status.description
      end

      stored = @store_credentials.call(account.email.to_s, secret.to_s)

      raise Error.new "Could not store login credentials." unless stored
      output << "Logged in as #{account.email.to_s.colorize.green}\n"

      secret.to_s
    end
  end
end
