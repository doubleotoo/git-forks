# TODO: add YARD MIT license
module GitForks
  module CLI
    # Handles help for commands
    class Fetch < Command
      def description; "Retrieves help for a command" end

      def run(*args)
        if args.first && cmd = CommandParser.get_command(args.first)
          cmd.run('--help')
        else
          puts "Command #{args.first} not found." if args.first
          CommandParser.run('--help')
        end
      end
    end
  end
end
