module CB
  class Identifier
    def initialize(@value : String = "")
      raise Program::Error.new "invalid identifier: '#{@value}'" unless eid? || api_name?
    end

    def ==(other : String)
      @value == other
    end

    def eid?
      EID_PATTERN.matches? @value
    end

    def api_name?
      return false if EID_PATTERN.matches? @value
      API_NAME_PATTERN.matches? @value
    end

    def to_s(io : IO)
      io << @value
    end
  end
end
