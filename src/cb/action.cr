require "log"
require "./client"

module CB
  # Action is the base class for all actions performed by `cb`.
  abstract class Action
    Log   = ::Log.for("Action")
    Error = Program::Error

    property input : IO
    property output : IO

    def initialize(@input = STDIN, @output = STDOUT)
    end

    def call
      Log.info { "calling #{self.class}" }
      run
    end
  end

  # APIAction performs some action utilizing the API.
  abstract class APIAction < Action
    property client : Client

    def initialize(@client, @input = STDIN, @output = STDOUT)
    end

    abstract def run

    macro eid_setter(property, description = nil)
      property {{property}} : String?

      def {{property}}=(str : String)
        raise_arg_error {{description || property.stringify.gsub(/_/, " ")}}, str unless str =~ EID_PATTERN
        @{{property}} = str
      end
    end

    # For simple identifiers such as region names, or plan names where we
    # expect only lowercase, numbers, and -
    macro ident_setter(property)
      property {{property}} : String?

      def {{property}}=(str : String)
        raise_arg_error {{property.stringify}}, str unless str =~ /\A[a-z0-9\-]+\z/
        @{{property}} = str
      end
    end

    macro i32_setter(property)
      property {{property}} : Int32?

      def {{property}}=(str : String)
        self.{{property}} = str.to_i(base: 10, whitespace: true, underscore: true, prefix: false, strict: true, leading_zero_is_octal: false)
      rescue ArgumentError
        raise_arg_error {{property.stringify}}, str
      end
    end

    # Note: unlike the other macros, this one does not create a nilable boolean,
    # and instead creates one that defaults to false
    macro bool_setter(property)
      property {{property}} : Bool = false

      def {{property}}=(str : String)
        case str.downcase
        when "true"
          self.{{property}} = true
        when "false"
          self.{{property}} = false
        else
          raise_arg_error {{property.stringify}}, str
        end
      end
    end

    # Nilable boolean setter. This is useful for fields where nil can have a
    # meaningful value beyond being falesy.
    macro bool_setter?(property)
      property {{property}} : Bool?

      def {{property}}=(str : String)
        case str.downcase
        when "true"
          self.{{property}} = true
        when "false"
          self.{{property}} = false
        else
          raise_arg_error {{property.stringify}}, str
        end
      end
    end

    private def raise_arg_error(field, value)
      raise Error.new "Invalid #{field.colorize.bold}: '#{value.to_s.colorize.red}'"
    end

    private def check_required_args
      missing = [] of String
      yield missing
      unless missing.empty?
        s = missing.size > 1 ? "s" : ""
        raise Error.new "Missing required argument#{s}: #{missing.map(&.colorize.red).join(", ")}"
      end
      true
    end

    private def print_team_slash_cluster(c)
      team_name = team_name_for_cluster c
      output << team_name << "/" if team_name
      output << c.name.colorize.t_name << "\n"
      team_name
    end

    private def team_name_for_cluster(c)
      team = client.get_team c.team_id
      team.name.colorize.t_alt
    end
  end
end
