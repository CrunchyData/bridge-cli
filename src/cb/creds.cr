struct CB::Creds
  getter host : String
  getter id : String
  getter secret : String

  CONFIG = Path["~/.config/cb"].expand(home: true)

  def initialize(@host, @id, @secret)
  end

  def self.for_host(host) : Creds?
    begin
      id, secret = File.read(CONFIG/host).split("\n")
    rescue File::Error
      return nil
    end

    return nil unless id && secret

    new(host, id, secret)
  end

  def store
    Dir.mkdir_p CONFIG
    File.open(CONFIG/host, "w", perm: 0o600) do |f|
      f << id << "\n" << secret
    end
    self
  end
end
