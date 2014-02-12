#!/usr/bin/env ruby

require_relative 'console'

class String
  # Returns a new string that has the leading and trailing whitespace trimmed.
  def trim
    tmp = self
    tmp.strip!
    return tmp
  end
end


$stdout.sync = true
$line_length = 0


# TODO: command object module
# command object takes line
# properties:
#   name
#   argument
#   started
#   barf?
# new
#    PhaseScriptExecution checks argument for RunUnitTests to determine type
# feed
#   does this command expect this line as a new subcommand?
#     if so: end current subcommand and start new
#     otherwise: if current subcommand, feed (recurse)
#     otherwise: else append to barf
# 
# Classes:
# xcodebuild
#     feed checks for build or clean commands
#         if not found, feed into current build command, if exists
#     if found, wrap up current command and replace
#
# build
#     feed checks for compiler command (which is a class cluster, which includes TestSuite?)
#         if not found, feed into current compiler command, if exists
#     if found, wrap up current command and replace
#
# testsuite
#     feed checks for test command (which is a class cluster, including testsuite and testcase)
#         if not found, feed into current test command, if exists
#     if found, wrap up current command and replace
#
# xcodebuild command expects build commands
#   build command expects Compile/Ln/Test
#     Compile (leaf)/Ln (leaf)/Test/etc (leafs) Test command expects Test Suite
#       Test Suite expects Test Suite/Test
#         Test Suite expects Test Suite/Test
#           Test Suite expects Test Suite/Test
#             Test (leaf)
#
# Print indentation increases with each level
#

$type = nil
$target = nil
$project = nil
$configuration = nil
$target_started = nil
TARGET = /=== ([A-Z]*) TARGET (.*) OF PROJECT (.*) WITH CONFIGURATION (.*) ===/
def parse_target(line)
  TARGET.match(line) do |matches|
    unless $target_started.nil?
      duration = ((Time.now - $target_started) * MSEC_PER_SEC).round
      Console.print "    Finished in #{duration} ms\n"
    end
    
    $type = matches[1].capitalize
    $target = matches[2]
    $project = matches[3]
    $configuration = matches[4]
    $target_started = Time.now
    
    Console.print "#{$type}: #{$target} / #{$project} (#{$configuration})\n"
  end
end


COMMANDS = {
  "Check dependencies" => "Check dependencies", # No arguments
  "Create product structure" => "Create product structure", # No arguments
  "Analyze" => "Analyze", # First argument is file
  "AnalyzeShallow" => "Analyze (shallow)", # First argument is file
  "CodeSign" => "Sign", # First argument is app
  "CompileC" => "Compile", # First argument is file
  "CompileXIB" => "Compile", # First argument is xib
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

TEST_COMMANDS = {
  "Test Suite" => "Test Suite",
  "Test Case" => "Test Case",
}

MSEC_PER_SEC = 1000

$command = nil
$command_argument = nil
$command_start = nil
$command_barf = nil

def command_is_compile(command)
  return ["Compile", "Link", "Analyze (deep)", "Analyze (shallow)", "Sign"].include?(command)
end

def print_command
  duration = ""
  unless $command_start.nil?
    duration = "(#{((Time.now - $command_start) * MSEC_PER_SEC).round} ms)"
  end
  
  Console.print "    #{$command} #{$command_argument}#{duration}"
  
  if command_is_compile($command) and $command_barf
    line = ""
    80.times { line = "#{line}━" }
    block = Console.bold(Console.black("#{line}\n#{$command_barf.strip}\n#{line}"))
    Console.append ":\n#{block}\n"
  end
  
  $command_barf = nil
end

COMMAND = /^([A-Za-z]+[\s]+)+/
PATH = /^([^\\ ]+(\\ )*)+/
def parse_command(line)
  if (COMMANDS.keys.any?{ |command| line.start_with?(command) })
    if ($command)
      print_command
    end
    
    matches = COMMAND.match(line)
    $command = COMMANDS[matches[0].trim] ? COMMANDS[matches[0].trim] : matches[0].trim
    rest_of_line = line[(matches[0].length)..-1]
    $command_argument = ""
    PATH.match(rest_of_line) do |matches|
      $command_argument = "#{File.basename(matches[0]).trim} "
    end
    
    $command_start = nil
    print_command
    $command_start = Time.now
    
    return
  end
  
  if (TEST_COMMANDS.keys.any?{ |command| line.start_with?(command) })
    Console.print "#{line}"
    return
  end
  
  if $command_barf.nil? and /^[^\s]/.match(line)
    $command_barf = line
  elsif $command_barf
    $command_barf += line
  end
end

STDIN.each do |line|
  parse_target(line)
  next if ($target.nil? or $project.nil? or $configuration.nil?)
  
  parse_command(line)
  next if $command.nil?
end

Console.print ""
# TODO: when we hit this spot we need to print Finished in # ms all the way back up to stdin
