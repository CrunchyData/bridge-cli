require "colorize"

module Colorize
  struct Colorize::Object(T)
    def t_id
      light_cyan
    end

    def t_name
      cyan
    end

    def t_warn
      red
    end

    def t_alt
      green
    end

    def t_success
      green
    end
  end
end

Colorize.on_tty_only!

class IO
  # no-op for non-file descriptor IOs, e.g. specs
  def noecho
    yield
  end
end

macro jrecord(name, *properties)
  record({{name}}, {{*properties}}) do
    include JSON::Serializable
    {{yield}}
  end
end

class URI
  def self.new(pull : JSON::PullParser)
    parse pull.read_string
  end
end

class String
  def to_i_cb
    to_i(base: 10, whitespace: true, underscore: true, prefix: false, strict: true, leading_zero_is_octal: false)
  end
end
