require_relative '../console'
require_relative 'command'

class Buildphase < Command
  @@commands = {
    "Check dependencies" => "Check dependencies", # No arguments
    "Create product structure" => "Create product structure", # No arguments
    "Analyze" => "Analyze", # First argument is file
    "AnalyzeShallow" => "Analyze (shallow)", # First argument is file
    "CodeSign" => "Sign", # First argument is app
    "CompileC" => "Compile", # First argument is file
    "CompileXIB" => "Compile", # First argument is xib
    "CopyPlistFile" => "Copy", # First argument is plist
    "CopyStringsFile" => "Copy", # First argument is file
    "CpHeader" => "Copy", # First argument is file
    "CpResource" => "Copy", # First argument is file
    "GenerateDSYMFile" => "Generate", # First argument is file
    "Ld" => "Link", # First argument is file
    "PhaseScriptExecution" => "Run Build Script", # Second argument is script
    "PBXCp" => "Copy", # First argument is file
    "ProcessInfoPlistFile" => "Process", # First argument is file
    "ProcessPCH" => "Precompile", # First argument is file
    "SetMode" => "Mode", # First argument is mode
    "SetOwnerAndGroup" => "Owner", # First argument is owner:group
    "SymLink" => "Symlink", # First argument is file
    "Touch" => "Touch", # First argument is file
  }
  @@command_regex = /^([A-Za-z]+[\s]+)+/
  @@path_regex = /^([^\\ ]+(\\ )*)+/
  
  def self.create(line)
    if @@commands.keys.any?{ |command| line.start_with?(command) }
      return self.new line
    end
    
    return nil
  end
  
  def initialize(line)
    super()
    
    matches = @@command_regex.match(line)
    raw_command = matches[0].strip
    @command = @@commands[raw_command] ? @@commands[raw_command] : raw_command
    
    # TODO: this could probably be better
    rest_of_line = line[(matches[0].length)..-1]
    @command_argument = ""
    @@path_regex.match(rest_of_line) do |matches|
      @command_argument = "#{File.basename(matches[0]).strip}"
    end
  end
  
  def start
    Console.print "    #{@command} #{@command_argument}"
  end
  
  def finish
    super
    
    Console.print "    #{$command} #{$command_argument}(#{self.duration} ms)"

    while @output.count > 0 and /^[\s]/.match(@output[0])
      @output.shift
    end
    
    if self.command_is_compile? and @output.count > 0
      line = ""
      80.times { line = "#{line}━" }
      block = Console.bold(Console.black("#{line}\n#{@output.join.strip}\n#{line}"))
      Console.append ":\n#{block}\n"
    end
  end
  
  def command_is_compile?
    return ["Compile", "Link", "Analyze (deep)", "Analyze (shallow)", "Sign"].include?(@command)
  end
end