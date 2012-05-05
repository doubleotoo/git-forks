# TODO: add YARD MIT license

# Launchy is used in 'browse' to open a browser.
require 'launchy'

module GitForks
  module CLI
    class List < Command
      # @return [Boolean] if I should list all forks in my
      #   cache
      attr_accessor :cached

      # @return [Boolean] if I should list all forks in my
      #   configuration
      attr_accessor :config

      # @return [Boolean] if I should list all forks even if
      #   they are not in my cache/configuration
      attr_accessor :remote

      def initialize
        super
        @cached = false
        @remote = false
        @config = false
      end

      def description; "List forks of [#{Github.repo_path}]" end

      # @todo should aggregate 'owner' from each source
      # @todo owner could be longer than default width... it will be truncated
      # @todo updated_at should be a relative "time ago"
      def run(*argv)
        optparse(*argv)
        forks = list(@remote, @config, @cached)

        output = []

        puts col_source('Source')     +
             col_owner('Owner')       +
             col_branches('Branches') +
             col_updated('Updated')

        if f = forks[:cached]
          f.each do |f|
            line = ""
            line << col_source('cached')
            line << col_owner(f['owner']['login'])
            line << col_branches(f['branches'].size)
            line << col_updated(f['updated_at'])
            output << line
          end
        end

        if f = forks[:config]
          f.each do |f|
            line = ""
            line << col_source('config')
            line << col_owner(f)
            line << col_branches('-')
            line << col_updated('-')
            output << line
          end
        end

        # TODO: this is duplicated code
        if f = forks[:remote]
          f.each do |f|
            line = ""
            line << col_source('remote')
            line << col_owner(f['owner']['login'])
            line << col_branches(f['branches'].size)
            line << col_updated(f['updated_at'])
            output << line
          end
        end

        puts output
      end

      def col_source(source, width=8)
        l(source, width)
      end

      def col_owner(owner, width=25)
        l(owner, width)
      end

      def col_branches(branch, width=12)
        l(branch, width)
      end

      def col_updated(updated, width=nil)
        updated
      end

      # Returns [Hash]
      #   :cached [Hash]
      #   :config [Array<String>]
      #   :remote [Hashie]
      def list(remote, config, cached)
        forks = {}
        forks[:cached] = Git::Cache.get_forks if cached
        forks[:config] = CLI::Config::List.new.list if config
        forks[:remote] = CLI::Fetch::Info.new.fetch if remote
        forks
      end

      # --fetch to update cache
      # @todo sort by column
      def optparse(*argv)
        opts = OptionParser.new do |o|
          o.banner = 'Usage: git forks list [options]'
          o.separator ''
          o.separator description
          o.separator ''
          o.separator 'Example: list the forks in my local cache and in GitHub'
          o.separator ''
          o.separator "         $ git forks list --cached --remote"
          o.separator '         cached: justintoo, rose-compiler'
          o.separator '         remote: justintoo, rose-compiler'
          o.separator ''
          o.separator "General options:"

          o.on('--cached', "List forks in my cache") do
            @cached = true
          end

          o.on('--config', "List forks in my configuration") do
            @config = true
          end

          o.on('--remote', "List forks in GitHub") do
            @remote = true
          end

          o.on('--remote', "List forks in GitHub") do
            @remote = true
          end

          o.on('--all', "List forks from each source (default)") do
            @remote = true
            @config = true
            @cached = true
          end

          common_options(o)
        end

        parse_options(opts, argv)
        log.warn "ignoring positional arguments: '#{argv}'" unless argv.empty?

        if not (@remote or @config or @cached)
          #puts opts
          #abort
          @remote = @config = @cached = true
        end

        argv
      end
    end
  end
end
