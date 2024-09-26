module CB::Model
  jrecord ConfigurationParameter,
    component : String? = nil,
    enum : Array(String) = [] of String,
    min_value : String? = nil,
    max_value : String? = nil,
    name : String = "",
    parameter_name : String? = nil,
    requires_restart : Bool = false,
    value : String? = nil do
    def to_s(io : IO)
      io << name.colorize.t_name << '=' << value
    end

    def value_str
      @value ? @value : "default"
    end
  end
end
