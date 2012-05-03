# TODO: add YARD MIT license

# Launchy is used in 'browse' to open a browser.
require 'launchy'

module GitForks
  module CLI
    # Handles help for commands
    class Browse < Command
      # @return [String] the GitHub fork owner
      attr_accessor :owners

      def initialize
        super
        self.owners = []
      end

      def description; "Shows a fork's GitHub page in a web browser." end

      # TODO:
      def run(*argv)
        optparse(*argv)
        log.info "#{self.owner}/#{Git.repo}"

        urls = []

        owners.each do |owner|
          owner, ref = owner.split(':')

          if f = fork(owner)
            url = f['html_url']

            if ref
              if ref.match(/[A-Za-z0-9]{40}/)
                url << "/commits/#{ref}"
              else
                url << "/tree/#{ref}"
              end
            end

            return Launchy.open(url)
          elsif owner == "network"
            # TODO:
          else
            puts "No such fork: '#{owner}/#{@repo}'. Maybe you need to run git-forks update?"
            puts
            list
          end
        end

        urls.each {|u| Launchy.open(u) }
      end

      # Parses the owner arguments.
      #
      # @example Parses a set of Fork owners
      #   parse_owners %w(owner1 owner2 owner3)
      # @param [Array<String>] owners the list of owners
      # @return [void]
      def parse_owners(*owners)
        self.owners = owners
      end

      def optparse(*argv)
        opts = OptionParser.new do |o|
          o.banner = 'Usage: git forks browse [options] [owner ...]'
          o.separator ''
          o.separator 'Example: git forks browse justintoo'
          o.separator ''
          o.separator description
          o.separator 'With no owner, the base repository\'s network page is opened.'
          o.separator ''

          common_options(o)
        end

        parse_options(opts, argv)
        parse_owners(*argv)
        argv
      end
    end
  end
end
