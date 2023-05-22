module CB
  class Spinner
    private property chars : Array(String)

    def initialize(@text : String = "", @io : IO = IO::Memory.new)
      @chars = ["|", "/", "-", "\\"].map { |c| "#{c.colorize.blue}" }
      @delay = 0.2
      @running = true
    end

    def start
      spawn do
        # Control Sequence to allow overwriting the line so that the spinner can
        # be properly animated.
        clear = @io.tty? ? "\u001b[0G" : "\u000d \u000d"

        # Allow the spinner iterator to restart when it reaches the end.
        spinner = @chars.each.cycle

        while @running
          @io << clear
          @io << "#{@text} #{spinner.next}"
          sleep @delay
        end

        @io << clear
        @io << "#{@text} done\n"
      end
    end

    def stop
      @running = false
    end
  end
end
