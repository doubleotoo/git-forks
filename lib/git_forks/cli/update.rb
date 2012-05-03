# TODO: add YARD MIT license

# Launchy is used in 'browse' to open a browser.
require 'launchy'

module GitForks
  module CLI
    class Update < Command
      # @return [String] the GitHub fork owner
      attr_accessor :owners

      def initialize
        super
        self.owners = []
      end

      def description; "Retrieve fork information via GitHub API v3." end

      def run(*argv)
        optparse(*argv)
        log.info "#{self.owner}/#{Git.repo}"
      end

      def optparse(*argv)
        opts = OptionParser.new do |o|
          o.banner = 'Usage: git forks update [options]'
          o.separator ''
          o.separator 'Example: git forks update'
          o.separator ''
          o.separator description
          o.separator ''

          common_options(o)
        end

        parse_options(opts, argv)
        argv
      end
    end
  end
end
