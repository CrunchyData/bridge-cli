# https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html

module CB::Dirs
  # $XDG_CONFIG_HOME defines the base directory relative to which user-specific
  # configuration files should be stored. If $XDG_CONFIG_HOME is either not set
  # or empty, a default equal to $HOME/.config should be used.
  CONFIG = cb_path "XDG_CONFIG_HOME", ".config"

  # $XDG_CACHE_HOME defines the base directory relative to which user-specific
  # non-essential data files should be stored. If $XDG_CACHE_HOME is either not
  # set or empty, a default equal to $HOME/.cache should be used.
  CACHE = cb_path "XDG_CACHE_HOME", ".cache"

  private def self.cb_path(env_var, default)
    base = xdg_path(env_var) || Path[ENV["HOME"], default]
    Path[base, "cb"]
  end

  private def self.xdg_path(env_var)
    val = ENV[env_var]?
    path = Path[val] if val
    # All paths set in these environment variables must be absolute. If an
    # implementation encounters a relative path in any of these variables it
    # should consider the path invalid and ignore it.
    return path if path.try &.absolute?
    nil
  end
end
