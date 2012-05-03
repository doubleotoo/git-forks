module GitForks
  module CLI
    class Config < CommandParser
      def description; "Configure which forks you are interested in (all by default)." end

      self.usage = "Usage: git forks config <command> [options]"
      self.commands_namespace = CLI::Config
      self.commands = [
        :add,
        :get,
        :list,
        :remove
      ]
      self.default_command = :list
    end
  end
end
