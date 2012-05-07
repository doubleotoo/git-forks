module GitForks
  module CLI
    class Review
      class Poll < Command
        # @return [String] optional list of specific forks to check
        attr_accessor :targets

        def initialize
          super
        end

        def description; "Poll GitHub repositories for new/updated branches (fetches git-refs)" end

        def run(*argv)
          optparse(*argv)
          @targets = Git::Cache.get_forks.collect {|f| f['owner']['login']} if @targets.empty?
          forks = poll(@targets)
          forks.each do |f|
            if new_refs = f['new-refs']
              new_refs.each do |sha, refs|
                puts "#{f['owner']['login']}:#{sha[0,8]} (#{refs.collect {|r| r[:ref]}.join(', ')})"
              end
            end
          end
        end

        def poll(targets = [])
          CLI::Fetch::Refs.new.fetch(targets)

          forks = Git::Cache.get_forks
          forks.select do |f|
            owner = f['owner']['login']
            log.info "Polling #{owner}/#{Github.repo}"

            refs = Git.fork_refs(owner)
            refs.each do |r|
              sha = r[:sha]
              ref = r[:ref]
              log.debug "#{owner}:#{sha} #{ref}"

              if Git.not_merged?(sha, 'origin/master')
                log.info "#{owner}:#{ref} (#{sha[0,8]}) (NEW)"
                f['new-refs'] ||= {}
                f['new-refs'][sha] ||= []
                f['new-refs'][sha] << r
                true
              else
                log.info "#{owner}:#{ref} (#{sha[0,8]}) already integrated"
                false
              end
            end
          end
        end

        def optparse(*argv)
          reverse = false
          opts = OptionParser.new do |o|
            o.banner = 'Usage: git forks review poll [options] [owners ...]'
            o.separator ''
            o.separator description
            o.separator ''
            o.separator 'Example: git forks review poll'
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
