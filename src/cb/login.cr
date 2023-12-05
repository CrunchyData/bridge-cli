require "retriable"
require "./action"

module CB
  class Login < Action
    private class LoginError < Exception
      def initialize(message)
        super("login error: #{message}")
      end
    end

    private class NoSession < Exception
      def initialize(message = "No session")
        super(message)
      end
    end

    private alias LoginResult = LoginInfo | LoginError

    private struct LoginInfo
      property account : CB::Model::Account
      property secret : String?

      def initialize(@account, @secret)
      end
    end

    property client : CB::Client = CB::Client.new CB::HOST

    # Library used for opening a browser. This should ONLY be overriden for
    # testing purposes.
    property lib_open : CB::Lib::Open.class = CB::Lib::Open

    property store_credentials : Proc(String, String, Bool) = ->(account : String, secret : String) : Bool {
      Credentials.store account: account, secret: secret
    }

    private def poll_login(channel : Channel(LoginResult), session_intent : CB::Model::SessionIntent)
      si_get_params = Client::SessionIntentGetParams.new(
        session_intent_id: session_intent.id,
        secret: "#{session_intent.secret}",
      )

      Retriable.retry(on: NoSession, base_interval: 1.seconds, multiplier: 1.0, rand_factor: 0.0) do
        session_intent = @client.get_session_intent(si_get_params)
        raise LoginError.new("login timed out") if Time.utc > session_intent.expires_at
        raise NoSession.new unless session_intent.session
      end

      secret = session_intent.session.try &.secret
      account = @client.get_account(secret)

      channel.send(LoginInfo.new account: account, secret: secret)
    end

    def run
      # Prevent login if API key ENV is set.
      raise Error.new "Cannot login with #{"CB_API_KEY".colorize.red.bold} set." if ENV["CB_API_KEY"]?

      # Request a session intent.
      si_params = Client::SessionIntentCreateParams.new(agent_name: "cb #{CB::VERSION}")
      session_intent = @client.create_session_intent si_params
      login_url = "https://www.crunchybridge.com/account/verify-cli/#{session_intent.id}?code=#{session_intent.code}"

      # Start polling for completion of session authentication.
      poll_login_channel = Channel(LoginResult).new
      spawn do
        poll_login(channel: poll_login_channel, session_intent: session_intent)
      rescue e : CB::Client::Error
        output << '\n'
        raise Error.new e.resp.status.description
      rescue e : LoginError
        poll_login_channel.send(e)
      end

      spinner = Spinner.new("Waiting for login...", output)

      # If the client can open a browser then prompt to do so. If the client is
      # headless or can't open a browser then only present a login url that can
      # be copied and pasted in to a browser.
      if lib_open.can_open_browser?
        output << "Press #{"Enter".colorize.bold} to open a browser to login. (#{"Ctrl+C".colorize.yellow} to quit)\n"
        output << "Or visit: #{login_url}"

        # Spawn a new fiber while we're waiting for user input. This is so that
        # we can continue on to wait for polling. The reason for this is that a
        # user might not want to simply copy/paste the URL and not have it
        # opened for them in a browser. If they were do that that they'd still
        # be stuck here until hitting `Enter`. So, we want to ensure that we can
        # reach the the point at which the session is received regardless of the
        # path they choose to take.
        spawn do
          input.gets
          spinner.start
          lib_open.run([login_url])
        end
      else
        output << "To login with Crunchy Bridge, please visit: #{login_url}\n"
        spinner.start
      end

      result = poll_login_channel.receive

      if result.is_a? LoginError
        spinner.stop "#{result.message.to_s.colorize.red}"
        result.message.to_s
      else
        spinner.stop "Done!"
        stored = @store_credentials.call(result.account.email.to_s, result.secret.to_s)

        raise Error.new "Could not store login credentials." unless stored
        output << "Logged in as #{result.account.email.to_s.colorize.green}\n"
        result.secret.to_s
      end
    end
  end
end
