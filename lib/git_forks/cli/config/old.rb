module GitForks
  module CLI
    class Config < Command
      attr_accessor :actions

      # @return [String] the GitHub fork owner
      attr_accessor :owners

      def initialize
        super
        self.actions  = {} # { :action => [owner1, owner2, ...], ... }
      end

      def description; "Configure which forks you are interested in (all by default)." end

      def run(*argv)
        optparse(*argv)
      end

      def add(*owners)
        owners.each do |o|
          if GitForks::Git::Config.get(GitForks::CONFIG_SECTION, o).nil?
            GitForks::Git::Config.add(GitForks::CONFIG_SECTION, o)
          else
            log.warn "'#{o}' already exists"
          end
        end
        nil
      end

      def get(*owners)
        ret=[]
        owners.each do |o|
          if r = GitForks::Git::Config.get(GitForks::CONFIG_SECTION, o)
            ret << r
          else
            log.warn "'#{o}' does not exist"
          end
        end
        ret
      end

      def list
        GitForks::Git::Config.get_all(GitForks::CONFIG_SECTION)
      end

      def remove(*owners)
        owners.each do |o|
          if GitForks::Git::Config.get(GitForks::CONFIG_SECTION, o).nil?
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
          o.on('-g', '--get=x[,y,z]', Array, 'Check for fork owner') do |owners|
            self.actions[:get] = owners
          end

          o.separator ""
          o.separator "Modifying values:"

          o.on('-a', '--add=x[,y,z]', Array, 'Adds owner to the forks list') do |owners|
            self.actions[:add] = owners
          end
          o.on('-r', '--remove=x[,y,z]', Array, 'Removes owner from the forks list') do |owners|
            self.actions[:remove] = owners
          end

          common_options(o)
        end

        parse_options(opts, argv)
        log.warn "ignoring positional arguments: '#{argv}'" unless argv.empty?
        self.actions.each do |action, owners|
          v = send action, owners
          puts v if v
        end
        puts list if has_list or self.actions.empty?
        argv
      end
    end
  end
end
