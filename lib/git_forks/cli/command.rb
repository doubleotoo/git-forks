# TODO: add YARD MIT License
require 'optparse'

module GitForks
  module CLI
    # Raised when a required positional argument is missing.
    class PositionalArgumentMissing < Exception
      def initialize(usage, msg = 'positional argument(s) missing')
        super(msg + "\n" + usage.to_s)
      end
    end

    # Abstract base class for CLI utilities. Provides some helper methods for
    # the option parser
    #
    # @abstract
    class Command
      # Helper method to run the utility on an instance.
      # @see #run
      def self.run(*argv) new.run(*argv) end

      def description; '' end

      protected

      # Adds a set of common options to the tail of the OptionParser
      #
      # @param [OptionParser] opts the option parser object
      # @return [void]
      def common_options(opts)
        opts.separator ""
        opts.separator "Other options:"
        opts.on_tail('-q', '--quiet', 'Show no warnings') { log.level = Logger::ERROR }
        opts.on_tail('--verbose', 'Show more information') { log.level = Logger::INFO }
        opts.on_tail('--debug', 'Show debugging information') { log.level = Logger::DEBUG }
        opts.on_tail('--backtrace', 'Show stack traces') { log.show_backtraces = true }
        opts.on_tail('-v', '--version', 'Show version') { puts "git-forks #{GitForks::VERSION}"; exit }
        opts.on_tail('-h', '--help', 'Show this help')  { puts opts; exit }
      end

      # Parses the option and gracefully handles invalid switches.
      # Positional arguments will be untouched in +argv+
      #
      # @param [OptionParser] opts the option parser object
      # @param [Array<String>] argv the arguments passed from input. This
      #   array will be modified.
      # @return [Void]
      def parse_options(opts, argv)
        opts.parse!(argv)
      rescue OptionParser::ParseError => err
        log.warn "Unrecognized/#{err.message}"
        argv.shift if argv.first && argv.first[0,1] != '-'
        retry
      end
    end
  end
end
