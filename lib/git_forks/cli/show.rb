# TODO: add YARD MIT license

module GitForks
  module CLI
    class Show < Command
      # @return [String] optional list of specific forks to check
      attr_accessor :targets

      # @return [Boolean] if I should list all forks even if
      #   they are not in my cache/configuration
      attr_accessor :remote

      def initialize
        super
        @targets = []
        @remote = false
      end

      def description; "Show fork details" end

      def run(*argv)
        optparse(*argv)
        show(@targets)
      rescue CLI::PositionalArgumentMissing => e
        log.error(e.message)
        log.backtrace(e) if log.level >= Logger::DEBUG
      end

      # @todo return hash and use 'smart-printing' to indent,
      #       set column widths, etc.
      def show(targets)
        if @remote
          forks = CLI::Fetch::Info.new.fetch(targets, false)
        else
          forks = Git::Cache.get_forks(targets)
        end

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
      end

      def optparse(*argv)
        opts = OptionParser.new do |o|
          o.banner = 'Usage: git forks show [options] owner ...'
          o.separator ''
          o.separator description
          o.separator ''
          o.separator "General options:"

          o.on('--remote', "Grab info from GitHub") do
            @remote = true
          end

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
