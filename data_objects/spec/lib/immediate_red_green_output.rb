module Bacon
  module ImmediateRedGreenOutput

    def handle_specification(name)
      yield
      @current_group = name
    end

    def handle_requirement(description)
      error = yield
      if error.empty?
        example_passed
      else
        example_failed(error, description, Counter[:specifications])
      end
    end

    def handle_summary
      puts
      counter = Counter.values_at(:specifications, :requirements, :failed, :errors)
      message = ("%d tests, %d assertions, %d failures, %d errors" % counter)
      color   = (counter[2].to_i != 0 || counter[3].to_i != 0 ? :red : :green)
      puts self.send(color, message)
    end

    private

    def example_failed(error, description, counter)
     if @current_group
        puts
        puts @current_group
        @current_group = nil  # only print the group name once
      end

      if error == "FAILED"
        puts red("- #{description} (FAILED - #{counter})")
        puts ErrorLog if Backtraces # dump stacktrace immediately
      else
        puts red("- #{description} (ERROR - #{counter})")
      end
    end

    def example_passed
      print green('.')
    end

    def red(s)    "\e[31m#{s}\e[0m"; end
    def green(s)  "\e[32m#{s}\e[0m"; end
    def yellow(s) "\e[33m#{s}\e[0m"; end

  end
end
