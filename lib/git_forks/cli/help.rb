# TODO: add YARD MIT license
module GitForks
  module CLI
    # Handles help for commands
    class Help < Command
      def description; "Retrieve help for a command" end

      def run(*argv)
        if argv.first && cmd = CommandParser.get_command(argv.first)
          cmd.run('--help')
        else
          puts "Command #{argv.first} not found." if argv.first
          CommandParser.run('--help')
        end
      end
    end
  end
end
