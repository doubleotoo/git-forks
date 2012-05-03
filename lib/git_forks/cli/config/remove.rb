module GitForks
  module CLI
    class Config
      class Remove < Command
        # @return [Boolean] if ALL the owners should be removed
        attr_accessor :all

        # @return [Array<String>] the list of owners to remove
        attr_accessor :owners

        def initialize
          super
          @all    = false
          @owners = []
        end

        def description; "Remove a fork from your configuration." end

        def run(*argv)
          @owners = optparse(*argv)
          if @all
            remove_all
          else
            remove(@owners)
          end
        rescue CLI::PositionalArgumentMissing => e
          log.error(e.message)
          log.backtrace(e) if log.level >= Logger::DEBUG
        end

        def remove(owners)
          owners.each do |o|
            if GitForks::Git::Config.get(GitForks::CONFIG_SECTION, o).nil?
              log.warn "'#{o}' does not exist"
            else
              GitForks::Git::Config.remove(GitForks::CONFIG_SECTION, o)
              log.info "Removed '#{o}' from your configuration"
            end
          end
          nil
        end

        # Return [Array<String>] list of removed owners
        def remove_all
          owners = GitForks::Git::Config.get_all(GitForks::CONFIG_SECTION)
          owners.each do |o|
            GitForks::Git::Config.remove(GitForks::CONFIG_SECTION, o)
            log.info "Removed '#{o}' from your configuration"
          end
          removed = owners
        end

        def optparse(*argv)
          reverse = false
          opts = OptionParser.new do |o|
            o.banner = 'Usage: git forks config remove owner ...'
            o.separator ''
            o.separator 'Example: git forks config remove justintoo rose-compiler'
            o.separator ''
            o.separator description
            o.separator ''
            o.separator "General options:"

            o.on('-a', '--all', 'Remove all forks from your configuration') do
              @all = true
            end

            common_options(o)
          end

          parse_options(opts, argv)
          if argv.empty? and not @all
            raise CLI::PositionalArgumentMissing, opts
          else
            @owners = argv
          end

          argv
        end
      end
    end
  end
end
