require_relative 'command'
require_relative 'buildaction'

class Prettify < Command
  def initialize
    super
    @subcommand_classes = [Buildaction]
  end
end