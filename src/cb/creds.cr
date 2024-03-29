require "json"
# TODO (abrightwell): Work this back in after initial browser login flow
# is determined to be good.
#
# require "keyring"
require "./dirs"

# TODO(abrightwell): Below we've intentionally commented out the path that will
# persist the credentials to the keyring service. This is so that we can work
# through and ensure the login flow is solid before introducing the new storage
# of credentials.  This WILL be updated before the next official release of
# `cb`.

module CB
  struct Credentials
    include JSON::Serializable

    private CREDENTIALS_FILE = Path[Dirs::CONFIG, CB::HOST]

    getter account : String
    property secret : String?

    def initialize(@account, @secret = nil)
    end

    def self.store(account : String, secret : String) : Bool
      creds = Credentials.new(account: account, secret: secret)

      # TODO (abrightwell): Work this back in after initial browser login flow
      #
      # is determined to be good.
      # stored = false
      #
      # begin
      #   # Let's remove any old credentials we might have stored. This is so that
      #   # storing credentials behaves more like an 'update' than a 'create'
      #   # since if an entry already exists it will raise an error.
      #   Keyring.delete(host, account) rescue Keychain::ItemNotFound
      #   stored = Keyring.set(host, account, secret)
      # rescue Keyring::NotAvailable
      #   creds.secret = secret
      # end

      Dir.mkdir_p Dirs::CONFIG
      File.open(CREDENTIALS_FILE, "w", perm: 0o600) do |f|
        f << creds.to_json
        true
      end
    rescue
      false
    end

    def self.get : String?
      return ENV["CB_API_KEY"] if ENV["CB_API_KEY"]?

      creds = File.open(CREDENTIALS_FILE, "r") { |f| Credentials.from_json(f) }
      creds.try &.secret.to_s
    rescue
      # TODO (abrightwell): Work this back in after initial browser login flow
      # is determined to be good.
      #
      #   return Keyring.get(host, creds.account)
      # rescue Keyring::NotAvailable
      # rescue Keyring::NotFound
      #   return nil
      # rescue
      #   return nil
    end

    def self.destroy : Bool
      # TODO (abrightwell): Work this back in after initial browser login flow
      # is determined to be good.
      #
      # deleted = false
      # begin
      #   creds = File.open(Dirs::CONFIG/host, "r") { |f| Credentials.from_json(f) }
      #   deleted = Keyring.delete(host, creds.account)
      # rescue
      # end
      File.delete?(CREDENTIALS_FILE)
      true
    rescue
      true
    end
  end
end
