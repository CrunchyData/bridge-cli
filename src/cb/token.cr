require "./cacheable"

struct CB::Token
  Cacheable.include key: host
  getter host : String
  getter token : String
  getter expires : Int64
  getter user_id : String
  getter name : String

  def initialize(@host, @token, @expires, @user_id, @name)
  end

  def self.for_host(host) : Token?
    fetch? host
  end

  def expires_at : Time
    Time.unix expires
  end
end
