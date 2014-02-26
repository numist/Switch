require_relative '../console'
require_relative 'command'

class TestSuite < Command
  @@suite_start_regex = /^Test Suite '([^']+)' started at [0-9\s:+-]+$/
  @@suite_end_regex = /^Executed ([0-9]+) test[s]?, with ([0-9]+) failure[s]? \(([0-9]+) unexpected\) in [0-9.]+ \([0-9.]+\) seconds$/
  def self.create(line)
    @@suite_start_regex.match(line) do |matches|
      return self.new(matches[1])
    end
    return nil
  end
  
  def initialize(suite_name)
    super()
    @subcommand_classes = [TestSuite, TestCase]
    @suite_name = suite_name
    @finished = false
  end
  
  def start
    Console.print "#{@indentation}Test suite #{@suite_name}\n"
  end
  
  def handle_new_output
    @@suite_end_regex.match(@output.last) do |matches|
      @tests_total = matches[1].to_i
      @tests_failed = matches[2].to_i
      @finished = true
    end
  end
  
  def finished?
    return @finished
  end
end

class TestCase < Command
  @@case_start_regex = /^Test Case '-\[[^\s]+ ([^\]]+)\]' started.$/
  @@case_end_regex = /^Test Case '-\[[^\]]+\]' ([a-z]+) \([0-9.]+ seconds\).$/
  def self.create(line)
    @@case_start_regex.match(line) do |matches|
      return self.new(matches[1])
    end
    return nil
  end

  def initialize(case_name)
    super()
    @case_name = case_name
    @finished = false
  end

  def start
    Console.print "#{@indentation}Test case #{@case_name}"
  end
  
  def handle_new_output
    @@case_end_regex.match(@output.last) do |matches|
      @status = matches[1]
      @finished = true
      @output.slice!(-1)
    end
  end
  
  def finished?
    return @finished
  end

  def finish
    super
    
    if @status == "failed"
      Console.print "#{@indentation}Test case #{@case_name} #{@status}"
    
      while @output.count > 0 and /^[\s]/.match(@output[0])
        @output.shift
      end
    
      if @output.count > 0
        line = ""
        80.times { line = "#{line}━" }
        block = Console.bold(Console.black("#{line}\n#{@output.join.strip}\n#{line}"))
        Console.append ":\n#{block}\n"
      else
        Console.append "\n"
      end
    end
  end
end
