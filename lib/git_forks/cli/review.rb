module GitForks
  module CLI
    class Review < CommandParser
      def description; "Manage GitHub pull requests (for code review)" end

      self.usage = "Usage: git forks review <command> [options]"
      self.commands_namespace = CLI::Review
      self.commands = [
        :create,
        :poll,
        :help
      ]
      self.default_command = :help
    end
  end
end
