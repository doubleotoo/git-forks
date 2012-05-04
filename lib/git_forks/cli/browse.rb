# TODO: add YARD MIT license

# Launchy is used in 'browse' to open a browser.
require 'launchy'

module GitForks
  module CLI
    # Handles help for commands
    class Browse < Command
      # @return [String] the GitHub fork owner
      attr_accessor :owners

      # @return [Boolean] if I should open my forks network page
      attr_accessor :network

      def initialize
        super
        @owners = []
        @repo = Github.repo
      end

      def description; "Show a fork's GitHub page in a web browser" end

      # @todo if Github.user: allow specifiers Github.user:<branch|sha>
      def run(*argv)
        optparse(*argv)

        urls = []
        invalid = []

        if @owners.empty?
          urls << Github.network_url
        else
          @owners.each do |owner|
            owner, ref = owner.split(':')

            if f = Git::Cache.get_fork(owner)
              if @network
                urls << "#{Github.endpoint}/#{owner}/#{Github.repo}/network"
              else
                url = f['html_url']
                if ref
                  if ref.match(/[A-Za-z0-9]{40}/)
                    url << "/commits/#{ref}"
                  else
                    url << "/tree/#{ref}"
                  end
                end
                urls << url
              end
            elsif owner == Github.user
              urls << Github.network_url
            else
              invalid << "#{owner}/#{Github.repo}"
            end
          end

          unless invalid.empty?
            invalid.each do |f|
              log.warn "No such fork: '#{f}'. Maybe you need to run `git forks fetch info`?"
            end
            log.info "This is your current forks configuration list: #{CLI::Config::List.new.list}"
          end
        end

        urls.each {|u|
          log.info "Launching browser to '#{u}'"
          Launchy.open(u)
        }
      end

      def optparse(*argv)
        opts = OptionParser.new do |o|
          o.banner = 'Usage: git forks browse [options] [owner ...]'
          o.separator ''
          o.separator description
          o.separator ''
          o.separator 'Example: git forks browse justintoo'
          o.separator 'Example: git forks browse justintoo:test-branch'
          o.separator "Example: git forks browse --network"
          o.separator "Example: git forks browse --network rose-compiler"
          o.separator ''
          o.separator 'If no owner is specified, the base repository\'s network page is opened.'
          o.separator ''
          o.separator "General options:"

          o.on('-n', '--network', "(Only) Browse the network of [owner/#{Github.repo}]") do
            @network = true
          end

          common_options(o)
        end

        parse_options(opts, argv)
        @owners = argv
        argv
      end
    end
  end
end
