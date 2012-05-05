module GitForks
  module CLI
    class Config
      class Add < Command
        # @return [String] list of fork owners to add
        attr_accessor :owners

        def initialize
          super
          @owners = []
        end

        def description; "Add a fork to your configuration" end

        def run(*argv)
          @owners = optparse(*argv)
          add(@owners)
        rescue CLI::PositionalArgumentMissing => e
          log.error(e.message)
          log.backtrace(e) if log.level >= Logger::DEBUG
        end

        def add(owners)
          owners.each do |o|
            if GitForks::Git::Config.get(GitForks::CONFIG_SECTION, o).nil?
              GitForks::Git::Config.add(GitForks::CONFIG_SECTION, o)
              log.info "Added '#{o}' to your forks configuration"
            else
              log.warn "'#{o}' already exists"
            end
          end
          nil
        end

        def optparse(*argv)
          reverse = false
          opts = OptionParser.new do |o|
            o.banner = 'Usage: git forks config add [options] owner ...'
            o.separator ''
            o.separator description
            o.separator ''
            o.separator 'Example: git forks config add justintoo rose-compiler'

            common_options(o)
          end

          parse_options(opts, argv)

          if argv.empty?
            raise CLI::PositionalArgumentMissing, opts
          else
            @owners = argv.uniq
          end
        end
      end
    end
  end
end
