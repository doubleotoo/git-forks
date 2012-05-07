module GitForks
  module CLI
    class Fetch
      class Refs < Command
        # @return [String] optional list of specific forks to check
        attr_accessor :targets

        def initialize
          super
          @targets = []
        end

        def description; "Fetch fork git-ref data from GitHub" end

        def run(*argv)
          optparse(*argv)
          @targets = Git::Cache.get_forks.collect {|f| f['owner']['login']} if @targets.empty?
          fetch(@targets)
        end

        def fetch(targets)
          targets.each do |t|
            log.info "Fetching GitHub refs for '#{t}'"
            Github.fetch_refs(t)
          end
        end

        def optparse(*argv)
          reverse = false
          opts = OptionParser.new do |o|
            o.banner = 'Usage: git forks fetch refs [options] [owners ...]'
            o.separator ''
            o.separator description
            o.separator ''
            o.separator 'Example: git forks fetch refs'
            o.separator ''
            o.separator "General options:"

            common_options(o)
          end

          parse_options(opts, argv)
          @targets = argv.uniq
        end
      end
    end
  end
end
