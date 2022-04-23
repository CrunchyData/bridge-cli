require "./cacheable"

struct CB::Token
  include Cacheable
  getter host : String
  getter token : String
  getter expires : Int64
  getter user_id : String
  getter name : String

  def self.suffix
    "token"
  end

  def initialize(@host, @token, @expires, @user_id, @name)
  end

  def self.for_host(host) : Token?
    fetch? host
  end

  def key : String
    host
  end

  def expires_at : Time
    Time.unix expires
  end
end
