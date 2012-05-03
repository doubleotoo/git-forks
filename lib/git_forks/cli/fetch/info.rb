module GitForks
  module CLI
    class Fetch
      class Info < Command
        # @return [Boolean] if we should cache the fetched data
        attr_accessor :cache

        # @return [String] the cache file name
        attr_accessor :cache_file

        def initialize
          super
          @cache = false
          @cache_file = GitForks::CACHE_FILE
        end

        def description; "Fetch fork information from GitHub" end

        def run(*argv)
          optparse(*argv)
          forks = fetch

          if @cache
            Git::Cache.save({:json => forks, :group => 'forks', :file => @cache_file})
          else
            puts JSON.pretty_generate(forks)
          end
        end

        def fetch
          forks = fetch_forks

          forks.each do |f|
            branches = fetch_branches(f)
            f.branches = branches
          end

          forks
        end

        def fetch_forks
          targets = CLI::Config::List.new.list # optional fork targets
          forks = Github.forks.select {|f|
            targets.empty? or targets.include?(f.owner.login)
          }

          unless targets.empty?
            owners = forks.collect {|f| f['owner']['login'] }
            if not (dne = targets - owners).empty?
              dne.each do |owner|
                puts "WARNING: #{owner}/#{Github.repo} does not exist."
                # `git forks fetch <dne>` will report <dne>
                # as not being in the forks whitelist. It is
                # in the list, but it doesn't exist in GitHub.
                #
                # Hopefully, this WARNING message will help.
              end
            end
          end
          forks
        end

        def fetch_branches(fork)
          fork_owner = fork['owner']['login']
          branches = Github.branches(fork_owner)
        end

        # TODO: option --dry-run: i.e. don't cache
        def optparse(*argv)
          reverse = false
          opts = OptionParser.new do |o|
            o.banner = 'Usage: git forks fetch info [options]'
            o.separator ''
            o.separator description
            o.separator ''
            o.separator 'Example: git forks fetch info'
            o.separator ''
            o.separator "General options:"

            o.on('-c', '--cache [file]', 'Cache the fetched data in [' + @cache_file + ']') do |file|
              @cache = true
              @cache_file = file if file
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
