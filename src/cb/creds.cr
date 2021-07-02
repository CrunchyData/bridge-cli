require "json"

struct CB::Creds
  include JSON::Serializable

  getter host : String
  getter id : String
  getter secret : String

  CONFIG = Path["~/.config/cb"].expand(home: true)

  def initialize(@host, @id, @secret)
  end

  def self.for_host(host) : Creds?
    begin
      creds = from_json File.read(CONFIG/host)
    rescue File::Error | JSON::ParseException
      return nil
    end

    creds
  end

  def store
    Dir.mkdir_p CONFIG
    File.open(CONFIG/host, "w", perm: 0o600) do |f|
      f << to_json
    end
    self
  end

  def delete
    File.delete CONFIG/host
  end
end
