MSEC_PER_SEC = 1000

class Command
  
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
  end
  
  #
  # Implementation details follow. Do not override any of these methods.
  #
  
  def duration
    return ((Time.now - @started) * MSEC_PER_SEC).round
  end
  
  def feed(line)
    # Does this line mark the start of a new command?
    new_command = @subcommand_classes.map{|subclass| subclass.create(line)}.detect{|command| !command.nil?}
    if !new_command.nil?
      # If there's a subcommand, wrap it up.
      unless @subcommand.nil?
        @subcommand.finish
      end
      @subcommand = new_command
      @subcommand.start
    elsif @subcommand.nil?
      @output.push line
      self.handle_new_output
    else
      @subcommand.feed line
    end
  end
end