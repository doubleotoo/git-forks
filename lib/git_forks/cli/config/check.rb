module GitForks
  module CLI
    class Config
      # @todo add --purge option to remove config forks that don't
      #       exist in GitHub (?)
      class Check < Command
        # @return [Boolean] if I should check against GitHub
        attr_accessor :remote

        # @return [Boolean] if I should check against my cache
        attr_accessor :cached

        # @return [String] optional list of specific forks to check
        attr_accessor :targets

        def initialize
          super
          @remote = false
          @cached = false
          @targets = []
        end

        def description; "Check if the forks in your configuration are valid" end

        def run(*argv)
          optparse(*argv)
          h = check(@cached, @remote, @targets)

          if @cached
            h[:cached].each do |owner, exists|
              puts "cached: #{owner} #{exists}"
            end
          end

          if @remote
            h[:remote].each do |owner, exists|
              puts "remote: #{owner} #{exists}"
            end
          end
        end

        # Returns [Hash]
        #   :cached [Hash<String,Boolean>] { owner => exists-in-cache }
        #   :remote [Hash<String,Boolean>] { owner => exists-in-github }
        def check(cached, remote, targets = [])
          ret = {}

          list = CLI::List.new.list(remote, true, cached)
          conf = list[:config]

          if targets.size > 0
            targets.each {|o| log.warn "'#{o}' is not in your configuration" if not conf.include?(o) }
            conf.select!  {|o| @targets.include?(o) }
          end

          if forks = list[:cached]
            ret[:cached] ||= {}

            forks = forks.collect {|f| f['owner']['login'] }
            conf.each do |owner|
              ret[:cached][owner] = forks.include?(owner)
            end
          end

          if forks = list[:remote]
            ret[:remote] ||= {}

            forks = forks.collect {|f| f['owner']['login'] }
            conf.each do |owner|
              ret[:remote][owner] = forks.include?(owner)
            end
          end

          ret
        end

        def optparse(*argv)
          reverse = false
          opts = OptionParser.new do |o|
            o.banner = 'Usage: git forks config check [options]'
            o.separator ''
            o.separator description
            o.separator ''
            o.separator "Example: delimiting with a newline (Bash)"
            o.separator ''
            o.separator "         $ git forks config list --separator $'\\n'"
            o.separator '         justintoo'
            o.separator '         rose-compiler'
            o.separator ''
            o.separator "General options:"

            o.on('-c', '--cached', 'Check against my cache') do
              @cached = true
            end

            o.on('-r', '--remote', 'Check against GitHub') do
              @remote = true
            end

            o.on('-a', '--all', 'Check against all sources (default)') do
              @cached = true
              @remote = true
            end

            common_options(o)
          end

          parse_options(opts, argv)

          if not (@remote or @cached)
            @remote = @cached = true
          end

          @targets = argv.uniq
        end
      end
    end
  end
end
