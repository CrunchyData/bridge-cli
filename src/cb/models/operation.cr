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

      def to_s
        super.to_s.underscore
      end

      def to_s(io : IO) : Nil
        io << to_s
      end
    end

    enum State
      Creating
      DisablingHA
      EnablingHA
      FailingOver
      InProgress
      Ready
      Scheduled
      WaitingForHAStandby

      def to_s
        super.to_s.underscore
      end

      def to_s(io : IO) : Nil
        io << to_s
      end
    end

    property flavor : Flavor
    property state : State
    property starting_from : String?

    def initialize(@flavor : Flavor,
                   @state : State,
                   @starting_from : String? = nil)
    end

    def one_line_state_display
      from = " (Starting from: #{starting_from})" if starting_from
      "#{state}#{from}"
    end
  end
end
