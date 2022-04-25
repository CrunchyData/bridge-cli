require "json"
require "./dirs"

module CB::Cacheable
  macro include(key)
    include ::CB::Cacheable
    def key
      {{key}}
    end
  end

  macro included
    include JSON::Serializable
    extend ::CB::Cacheable::ClassMethods
  end

  CACHE_DIR = Dirs::CACHE

  module ClassMethods
    def suffix
      name.split("::").last.downcase
    end

    def fetch?(key)
      begin
        token = from_json File.read(file_path(key))
      rescue File::Error | JSON::ParseException
        return nil
      end

      return nil unless token
      return nil if Time.local > token.expires_at

      token
    end

    protected def file_path(key)
      CACHE_DIR / "#{key}.#{suffix}"
    end
  end

  abstract def key
  abstract def expires_at : Time

  def store
    Dir.mkdir_p CACHE_DIR
    File.open(self.class.file_path(key), "w", perm: 0o600) do |f|
      f << to_json
    end
    self
  end
end
