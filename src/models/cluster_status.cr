require "json"

module CB::Model
  struct ClusterStatus
    include JSON::Serializable

    enum State
      Creating
      Destroying
      Unknown
      Ready
      Restarting
      Resuming
      Suspended
      Suspending

      def to_s(io : IO)
        io << self.to_s.downcase
      end
    end

    property oldest_backup_at : String?
    property state : State

    def initialize(@oldest_backup_at = nil, @state = State::Unknown)
    end
  end
end
