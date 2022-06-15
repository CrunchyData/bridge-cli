require "./cacheable"

# TODO (abrightwell): We had to explicitly qualify this class name as an
# `Action` due to conflicts with the below `Token` struct.  Would be great to
# potentially namespace actions under `CB::Action` or something. Something
# perhaps worth considering.
class CB::TokenAction < CB::Action
  enum Format
    Default
    Header
  end

  property token : Token
  property format : Format = Format::Default

  def initialize(@token, @input, @output)
  end

  def run
    case @format
    when "header"
      output << "Authorization: Bearer #{token.token}"
    when "default"
      output << token.token
    end
  end
end

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

  def self.delete(host)
    File.delete(file_path(host)) if File.exists?(file_path(host))
  end

  def expires_at : Time
    Time.unix expires
  end
end
