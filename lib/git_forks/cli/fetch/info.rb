module GitForks
  module CLI
    class Fetch
      class Info < Command
        def initialize
          super
        end

        def description; "Add a fork to your configuration" end

        def run(*argv)
          optparse(*argv)
          data = fetch
          Git::Cache.save({:json => data, :group => 'forks'})
        end

        def fetch
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

        # TODO: option --dry-run: i.e. don't cache
        def optparse(*argv)
          reverse = false
          opts = OptionParser.new do |o|
            o.banner = 'Usage: git forks fetch info [options]'
            o.separator ''
            o.separator description
            o.separator ''
            o.separator 'Example: git forks fetch info'

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
