module GitForks
  module CLI
    class Config
      class List < Command
        # @return [Boolean] if the size of the list should be
        #   printed
        attr_accessor :count

        # @return [Boolean] if the output list should be in reverse
        #   lexicographic order
        attr_accessor :reverse

        def initialize
          super
          @count    = false
          @reverse  = false
        end

        def description; "List the forks you have configured" end

        def run(*argv)
          optparse(*argv)
          owners = list
          if @count
            owners = owners.size
          end
          puts owners
          owners
        end

        def list
          owners = GitForks::Git::Config.get_all(GitForks::CONFIG_SECTION).sort
          owners.reverse! if @reverse
          owners
        end

        def optparse(*argv)
          reverse = false
          opts = OptionParser.new do |o|
            o.banner = 'Usage: git forks config list [options]'
            o.separator ''
            o.separator description
            o.separator ''
            o.separator 'Example: git forks config list'
            o.separator ''
            o.separator "General options:"

            o.on('-c', '--count', 'Print the total number of fork owners (only)') do
              @count = true
            end

            o.on('-r', '--reverse', 'Sort the list in reverse lexicographic order') do
              @reverse = true
            end

            common_options(o)
          end

          parse_options(opts, argv)
          log.warn "ignoring positional arguments: '#{argv}'" unless argv.empty?

          argv
        end
      end
    end
  end
end
