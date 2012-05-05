module GitForks
  module CLI
    class Config
      class Get < Command
        # @return [Boolean] if the output list should be in reverse
        #   lexicographic order
        attr_accessor :reverse

        # @return [String] list of fork owners to get
        attr_accessor :owners

        def initialize
          super
          @reverse = false
          @owners  = []
        end

        def description; "Get a fork by owner name from your configuration" end

        def run(*argv)
          optparse(*argv).sort
          @owners.reverse! if @reverse
          owners = get(@owners)

          puts owners
          owners
        rescue CLI::PositionalArgumentMissing => e
          log.error(e.message)
          log.backtrace(e) if log.level >= Logger::DEBUG
        end

        def get(owners)
          ret=[]
          owners.each do |o|
            if r = GitForks::Git::Config.get(GitForks::CONFIG_SECTION, o)
              ret << r
            else
              log.warn "'#{o}' does not exist"
            end
          end
          ret
        end

        def optparse(*argv)
          reverse = false
          opts = OptionParser.new do |o|
            o.banner = 'Usage: git forks config get [options] owner ...'
            o.separator ''
            o.separator description
            o.separator ''
            o.separator 'Example: git forks config get justintoo rose-compiler'
            o.separator ''
            o.separator "General options:"

            o.on('-r', '--reverse', 'Sort the list in reverse lexicographic order') do
              @reverse = true
            end

            common_options(o)
          end

          parse_options(opts, argv)
          raise CLI::PositionalArgumentMissing, opts if argv.empty?

          @owners = argv.uniq
        end
      end
    end
  end
end
