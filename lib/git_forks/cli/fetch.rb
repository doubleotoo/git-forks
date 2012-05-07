module GitForks
  module CLI
    class Fetch < CommandParser
      def description; "git-fetch fork data from GitHub" end

      self.usage = "Usage: git forks fetch <command> [options]"
      self.commands_namespace = CLI::Fetch
      self.commands = [
        :info,
        :refs,
        :help
      ]
      self.default_command = :help
    end
  end
end
