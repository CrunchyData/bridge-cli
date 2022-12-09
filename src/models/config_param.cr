module CB::Model
  jrecord ConfigurationParameter,
    component : String? = nil,
    name : String = "",
    parameter_name : String? = nil,
    requires_restart : Bool = false,
    value : String? = nil do
    @[JSON::Field(key: "parameter_name", emit_null: false)]
    def to_s(io : IO)
      io << name.colorize.t_name << '=' << value
    end

    def value_str
      @value ? @value : "default"
    end
  end
end
