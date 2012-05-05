# TODO: add YARD MIT license

module GitForks
  module CLI
    class Show < Command
      # @return [String] optional list of specific forks to check
      attr_accessor :targets

      def initialize
        super
        @targets = []
      end

      def description; "Show fork details" end

      def run(*argv)
        optparse(*argv)
        show(@targets)
      rescue CLI::PositionalArgumentMissing => e
        log.error(e.message)
        log.backtrace(e) if log.level >= Logger::DEBUG
      end

      def show(targets)
        forks = Git::Cache.get_forks(targets)
        i=0; forks.each do |f|
          puts if i > 0
          puts "Owner    : #{f['owner']['login']}"
          puts "Repo     : #{Github.repo}"
          puts "Created  : #{strftime(f['created_at'])}"
          puts "Updated  : #{strftime(f['updated_at'])}"
          puts "Branches : #{f['branches'].size}"
          f['branches'].each do |b|
            puts "  #{b['commit']['sha']} #{b['name']}"
          end
        i +=1
        end

        # if remote; fetch
      end

      def optparse(*argv)
        opts = OptionParser.new do |o|
          o.banner = 'Usage: git forks show [options] owner ...'
          o.separator ''
          o.separator description
          o.separator ''
          o.separator "General options:"

          common_options(o)
        end

        parse_options(opts, argv)

        if argv.empty?
          raise CLI::PositionalArgumentMissing, opts
        else
          @targets = argv.uniq
        end
      end
    end
  end
end
