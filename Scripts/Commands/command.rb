MSEC_PER_SEC = 1000

class Command
  @@level = 0
  
  # Stubs to be overridden by subclasses:
  def self.create(line)
    return nil
  end
  
  # Do any intialization with side effects (like console output) here instead of in :initialize
  def start
  end
  
  # Called whenever a new line of output is available for this command
  def handle_new_output
  end

  # Subclasses overriding :finish MUST call super FIRST!
  def finish
    unless @subcommand.nil?
      @subcommand.finish
    end
  end
  
  # Subclasses overriding :initialize MUST call super FIRST!
  def initialize
    @output = []
    @started = Time.now
    # Subclasses should override this ivar with a list of valid subcommand types.
    @subcommand_classes = [Command]
    
    @indentation = ""
    @@level.times { @indentation = "#{@indentation}  " }
  end
  
  #
  # Implementation details follow. Do not override any of these methods.
  #
  
  attr_reader :indentation
  attr_accessor :subcommand
  attr_reader :subcommand_classes
  attr_reader :output
  
  def duration
    return ((Time.now - @started) * MSEC_PER_SEC).round
  end
  
  def feed(line)
    # Build a stack of current unfinished commands:
    commands = [self]
    while commands.last.subcommand
      commands.push(commands.last.subcommand)
    end
    commands = commands.reject{|command| command.respond_to?(:finished?) and command.finished?}
    
    # Get all the possible new commands that this line may represent.
    new_commands = commands.map do |command|
      @@level = commands.index(command)
      command.subcommand_classes.map{|subclass| subclass.create(line)}.detect{|command| !command.nil?}
    end
    
    # The last new command is the one we want to assign to its corresponding parent.
    last_new_command_index = new_commands.rindex{|command| !command.nil?}
    
    if !last_new_command_index.nil?
      unless commands[last_new_command_index].subcommand.nil?
        commands[last_new_command_index].subcommand.finish
      end
      commands[last_new_command_index].subcommand = new_commands[last_new_command_index]
      commands[last_new_command_index].subcommand.start
    elsif !commands.last.respond_to?(:finished) or !commands.last.finished?
      commands.last.output.push(line)
      commands.last.handle_new_output
    end
  end
end