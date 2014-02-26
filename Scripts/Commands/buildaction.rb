require_relative '../console'
require_relative 'command'
require_relative 'buildphase'

class Buildaction < Command
  @@target_regex = /=== ([A-Z]*) TARGET (.*) OF PROJECT (.*) WITH CONFIGURATION (.*) ===/
  def self.create(line)
    @@target_regex.match(line) do |matches|
      return self.new(type: matches[1].capitalize, target: matches[2], project: matches[3], configuration: matches[4])
    end
    
    return nil
  end
  
  def initialize(type:nil, target:nil, project:nil, configuration:nil)
    super()
    
    @subcommand_classes = [Buildphase]
    
    @type = type
    @target = target
    @project = project
    @configuration = configuration
  end
  
  def start
    Console.print "#{@type}: #{@target} / #{@project} (#{@configuration})\n"
  end
  
  def finish
    super
    Console.print "    #{@type}: finished in #{self.duration} ms\n"
  end
end