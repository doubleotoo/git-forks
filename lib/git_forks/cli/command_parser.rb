module GitForks
  module CLI
    # This class parses a command name out of the +git-forks+ CLI command and calls
    # that command in the form:
    #
    #   $ git forks command_name [options]
    #
    # If no command or arguments are specified, or if the arguments immediately
    # begin with a +--opt+ (not +--help+), the {default_command} will be used
    # (which itself defaults to +:help+).
    #
    # @see Command
    # @see commands
    # @see default_command
    class CommandParser
      class << self
        # @return [Hash{Symbol => Command}] the mapping of command names to
        #   command classes to parse the user command.
        attr_accessor :commands

        # @return [Symbol] the default command name to use when no options
        #   are specified or
        attr_accessor :default_command
      end

      self.commands = [
        :browse,
        :config,
        :fetch,
        :help,
        :list,
        :show,
        :update
      ]

      self.default_command = :Help

      def self.get_command(str)
        if i = self.commands.index(str.to_sym)
          self.commands[i].capitalize.to_class(CLI)
        else
          nil
        end
      end

      # Convenience method to create a new CommandParser and call {#run}
      # @return (see #run)
      def self.run(*args) new.run(*args) end

      def initialize
        log.show_backtraces = false
      end

      # Runs the {Command} object matching the command name of the first
      # argument.
      # @return [void]
      def run(*args)
        if %w(-h --help).include?(args.first)
          list_commands
        elsif %w(-v --version).include?(args.first)
          puts "git-forks v#{GitForks::VERSION}"
        else
          if args.size == 0 || args.first =~ /^-/
            command_name = self.class.default_command
          else
            command_name = args.first.to_sym
            args.shift
          end
          if command = CommandParser.get_command(command_name)
            return command.run(*args)
          end
        end
      end

      private

      def commands; self.class.commands end

      def list_commands
        puts "Usage: git forks <command> [options]"
        puts
        puts "Commands:"
        commands.sort_by {|k| k.to_s }.each do |command_name|
          command = CommandParser.get_command(command_name).new
          puts "%-8s %s" % [command_name, command.description]
        end
      end
    end
  end
end
