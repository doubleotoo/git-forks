module GitForks
  module CLI
    class Config < Command
      attr_accessor :action

      # @return [String] the GitHub fork owner
      attr_accessor :owners

      def initialize
        super
        self.owners = []
      end

      def description; "Configure which forks you are interested in (all by default)." end

      def run(*argv)
        optparse(*argv)
      end

      # TODO:
      def add(*owners)
        owners.each do |o|
          if get(o).nil?
            GitForks::Git::Config.add(GitForks::CONFIG_SECTION, o)
          else
            log.warn "'#{o}' already exists"
          end
        end
        nil
      end

      def get(*owner)
        GitForks::Git::Config.get(GitForks::CONFIG_SECTION)
      end

      def list
        GitForks::Git::Config.get_all(GitForks::CONFIG_SECTION)
      end

      def remove(*owners)
        owners.each do |o|
          if get(o).nil?
            log.warn "'#{o}' does not exist"
          else
            GitForks::Git::Config.remove(GitForks::CONFIG_SECTION, o)
          end
        end
        nil
      end

      def optparse(*argv)
        has_list = false
        opts = OptionParser.new do |o|
          o.banner = 'Usage: git forks config [options]'
          o.separator ''
          o.separator 'Example: git forks config --list'
          o.separator ''
          o.separator description
          o.separator ''
          o.separator "General options:"

          o.on('-l', '--list', 'List current fork owners') do
            has_list = true
          end
          o.on('-g', '--get', 'Check for fork owner') do
            self.action = :get
          end

          o.separator ""
          o.separator "Modifying values:"

          o.on('-a', '--add', 'Adds owner to the forks list') do
            self.action = :add
          end
          o.on('-r', '--remove', 'Removes owner from the forks list') do
            self.action = :remove
          end

          common_options(o)
        end

        parse_options(opts, argv)
        if self.action
          v = send self.action, *argv
          puts v if v
        end
        puts list if has_list or self.action.nil?
        argv
      end
    end
  end
end
