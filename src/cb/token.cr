require "json"
require "./dirs"

struct CB::Token
  include JSON::Serializable

  getter host : String
  getter token : String
  getter expires : Int64
  getter user_id : String
  getter name : String

  CACHE = Dirs::CACHE

  def initialize(@host, @token, @expires, @user_id, @name)
  end

  def self.for_host(host) : Token?
    begin
      token = from_json File.read(CACHE/"#{host}.token")
    rescue File::Error | JSON::ParseException
      return nil
    end

    return nil unless token
    return nil if Time.local.to_unix > token.expires

    token
  end

  def store
    Dir.mkdir_p CACHE
    File.open(CACHE/"#{host}.token", "w", perm: 0o600) do |f|
      f << to_json
    end
    self
  end
end
