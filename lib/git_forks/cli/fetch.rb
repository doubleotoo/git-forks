module GitForks
    puts '  fetch [<owners>]        git-fetch fork data from GitHub. (Forces cache update.)'
    puts '                          <owners> is a space separate list.'
  module CLI
    # Lists all constant and method names in the codebase. Uses {Yardoc} --list.
    class Fetch < Command
      def description; 'git-fetch data from GitHub. (Runs `git-fork update`)' end

      # Runs the commandline utility, parsing arguments and displaying a
      # list of objects
      #
      # @param [Array<String>] args the list of arguments.
      # @return [void]
      def run(*args)
        if args.include?('--help')
          puts "Usage: git forks fetch [options]"
        else
          GitForks.run('--list', *args)
        end
      end
    end
  end
end
