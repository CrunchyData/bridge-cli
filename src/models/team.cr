require "json"

module CB::Model
  struct Team
    include JSON::Serializable

    property billing_email : String?

    property id : String

    property is_personal : Bool

    property name : String

    property role : String?

    property enforce_sso : Bool?

    def initialize(@id, @name, @is_personal,
                   @billing_email = nil,
                   @enforce_sso = nil,
                   @role = nil)
    end

    def name
      is_personal ? "personal" : @name
    end

    def to_s(io : IO)
      io << "#{id.colorize.t_id} (#{name.colorize.t_name})"
    end
  end
end
