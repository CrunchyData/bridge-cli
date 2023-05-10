require "json"

module CB::Model
  # Upgrade operation.
  struct Operation
    include JSON::Serializable

    enum Flavor
      HAChange
      Maintenance
      MajorVersionUpgrade
      Resize

      def to_s(io : IO)
        io << to_s.underscore.gsub('_', ' ')
      end
    end

    enum State
      Canceling
      Creating
      DisablingHA
      EnablingHA
      FailingOver
      InProgress
      Ready
      ReplayingWAL
      Scheduled
      WaitingForHAStandby

      def to_s(io : IO) : Nil
        io << to_s.underscore.gsub('_', ' ')
      end
    end

    property flavor : Flavor
    property state : State
    property starting_from : String?

    def initialize(@flavor : Flavor,
                   @state : State,
                   @starting_from : String? = nil)
    end
  end
end
