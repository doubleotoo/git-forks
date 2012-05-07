# TODO: add YARD MIT license
module GitForks
  module CLI
    class Review
      # Handles help for commands
      class Help < Command
        def description; "Retrieves help for a command" end

        def run(*argv)
          if argv.first && cmd = Review.get_command(argv.first)
            cmd.run('--help')
          else
            puts "Command #{argv.first} not found." if argv.first
            Review.run('--help')
          end
        end
      end
    end
  end
end
