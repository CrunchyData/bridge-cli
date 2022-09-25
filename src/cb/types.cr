module CB
  struct Role
    getter name : String

    VALID_CLUSTER_ROLES = Set{"application", "default", "postgres", "user"}

    private INVALID_ROLE_MESSAGE = "invalid role: '%s'. Must be one of: #{VALID_CLUSTER_ROLES.join ", "}"

    def ==(name : String)
      @name == name
    end

    def initialize(@name : String = "default")
      raise Program::Error.new INVALID_ROLE_MESSAGE % @name unless valid?
    end

    def valid?
      return true if EID_PATTERN.matches? @name.lchop("u_")
      VALID_CLUSTER_ROLES.includes? @name
    end

    def to_s(io : IO)
      io << @name
    end
  end
end
