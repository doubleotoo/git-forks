module GitForks
  module CLI
    class Config
      module List
        def initialize
          super
          self.owners = []
        end

        def description; "Configure which forks you are interested in (all by default)." end

        def run(*argv)
          optparse(*argv)
        end

        def optparse(*argv)
          opts = OptionParser.new do |o|
            o.banner = 'Usage: git forks config [options]'
            o.separator ''
            o.separator 'Example: git forks config --list'
            o.separator ''
            o.separator description
            o.separator ''
            o.separator "General options:"

            o.on('-l', '--list', 'List current owners configuration') do
              list = true
            end
            opts.on('-g', '--get', 'Check for <owner>') do
              self.reset = true
            end

            opts.separator ""
            opts.separator "Modifying keys:"

            opts.on('-a', '--append', 'Appends items to existing key values') do
              self.append = true
            end
            opts.on('--as-list', 'Forces the value(s) to be wrapped in an array') do
              self.as_list = true
            end


            common_options(o)
          end

          parse_options(opts, argv)
          argv
        end
      end
    end # List
  end # Config
end # GitForks
