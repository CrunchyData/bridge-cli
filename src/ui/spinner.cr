module CB
  class Spinner
    private property chars : Array(String)

    def initialize(@text : String = "", @io : IO = IO::Memory.new)
      @chars = ["|", "/", "-", "\\"].map { |c| "#{c.colorize.blue}" }
      @delay = 200.milliseconds
      @running = false

      # Control Sequence to allow overwriting the line so that the spinner can
      # be properly animated.
      @clear = @io.tty? ? "\u001b[0G" : "\u000d \u000d"
    end

    def start
      @running = true
      spawn do
        # Allow the spinner iterator to restart when it reaches the end.
        spinner = @chars.each.cycle

        while @running
          @io << @clear
          @io << "#{@text} #{spinner.next}"
          sleep @delay
        end
      end
    end

    def stop(message : String)
      @running = false
      @io << @clear
      @io << "#{@text} #{message}\n"
    end
  end
end
