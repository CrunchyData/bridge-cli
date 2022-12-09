require "option_parser"

class OptionParser
  property examples : String?

  # Allows for hiding an option from help.
  #
  # Note the only difference between this and the most commonly used form of
  # `#on` is that the `description` string is omitted.
  def on(flag : String, &block : String ->)
    flag, value_type = parse_flag_definition(flag)
    @handlers[flag] = Handler.new(value_type, block)
  end

  def to_s(io : IO) : Nil
    if banner = @banner
      io << "Usage".colorize.bold << ":\n"
      io << "    " << banner << '\n'
    end

    commands = [] of String
    flags = [] of String

    # filter out commands and flags
    @flags.each do |flag|
      if flag.lstrip.starts_with? '-'
        flags << flag
      else
        commands << flag
      end
    end

    if !commands.empty?
      io << '\n' << "Commands".colorize.bold << ":\n"
      io << commands.sort.join io, '\n'
      io << '\n'
    end

    if !flags.empty?
      io << '\n' << "Options".colorize.bold << ":\n"
      flags.sort_by(&.lstrip(" -")).join io, '\n'
      io << '\n'
    end

    if examples
      io << '\n' << "Examples".colorize.bold << ":\n"
      io << examples << '\n'
    end
  end
end
