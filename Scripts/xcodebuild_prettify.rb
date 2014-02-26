#!/usr/bin/env ruby

require_relative 'console'
require_relative 'commands/prettify'

COMMANDS = {
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

$command = nil
$command_argument = nil
$command_start = nil
$command_barf = nil

def command_is_compile(command)
  return ["Compile", "Link", "Analyze (deep)", "Analyze (shallow)", "Sign"].include?(command)
end

def print_command
  # duration = ""
  # unless $command_start.nil?
  #   duration = "(#{((Time.now - $command_start) * MSEC_PER_SEC).round} ms)"
  # end
  # 
  # Console.print "    #{$command} #{$command_argument}#{duration}"
  # 
  # if command_is_compile($command) and $command_barf
  #   line = ""
  #   80.times { line = "#{line}━" }
  #   block = Console.bold(Console.black("#{line}\n#{$command_barf.strip}\n#{line}"))
  #   Console.append ":\n#{block}\n"
  # end
  # 
  # $command_barf = nil
end

COMMAND = /^([A-Za-z]+[\s]+)+/
PATH = /^([^\\ ]+(\\ )*)+/
def parse_command(line)
  if (COMMANDS.keys.any?{ |command| line.start_with?(command) })
    if ($command)
      print_command
    end
    
    matches = COMMAND.match(line)
    $command = COMMANDS[matches[0].strip] ? COMMANDS[matches[0].strip] : matches[0].strip
    rest_of_line = line[(matches[0].length)..-1]
    $command_argument = ""
    PATH.match(rest_of_line) do |matches|
      $command_argument = "#{File.basename(matches[0]).strip} "
    end
    
    $command_start = nil
    print_command
    $command_start = Time.now
    
    return
  end
  
  if $command_barf.nil? and /^[^\s]/.match(line)
    $command_barf = line
  elsif $command_barf
    $command_barf += line
  end
end


prettify = Prettify.new

STDIN.each do |line|
  prettify.feed line
  
  parse_command(line)
  next if $command.nil?
end

prettify.finish

Console.print ""
