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

      # @return [String] used to delimit components in the list
      attr_accessor :separator
      DEFAULT_SEPARATOR = ' '

      def initialize
        super
        @cached = false
        @remote = false
        @config = false
        @separator = DEFAULT_SEPARATOR
      end

      def description; "List forks of [#{Github.repo_path}]" end

      def run(*argv)
        optparse(*argv)
        forks = list(@remote, @config, @cached)

        if f = forks[:cached]
          puts "cached: #{f.collect {|f| f['owner']['login'] }.sort.join(@separator)}"
        end

        if f = forks[:config]
          puts "config: #{f.join(@separator)}"
        end

        if f = forks[:remote]
          puts "remote: #{f.collect {|f| f['owner']['login'] }.sort.join(@separator)}"
        end
      end

      # Returns [Hash]
      #   :cached [Hash]
      #   :config [Array<String>]
      #   :remote [Hashie]
      def list(remote, config, cached)
        forks = {}
        forks[:cached] = Git::Cache.get_forks.collect if cached
        forks[:config] = CLI::Config::List.new.list if config
        forks[:remote] = Github.forks.collect if remote
        forks
      end

      def optparse(*argv)
        opts = OptionParser.new do |o|
          o.banner = 'Usage: git forks list [options]'
          o.separator ''
          o.separator description
          o.separator ''
          o.separator 'Example: list the forks in my local cache and in GitHub'
          o.separator ''
          o.separator "         $ git forks list --cached --remote --separator ', '"
          o.separator '         cached: justintoo, rose-compiler'
          o.separator '         remote: justintoo, rose-compiler'
          o.separator ''
          o.separator "General options:"

          o.on('--all', "List forks from each source (default)") do
            @remote = true
            @config = true
            @cached = true
          end

          o.on('--cached', "List forks in my cache") do
            @cached = true
          end

          o.on('--config', "List forks in my configuration") do
            @config = true
          end

          o.on('--remote', "List forks in GitHub") do
            @remote = true
          end

          o.on('--separator STR', String, "List separator (default: '#{DEFAULT_SEPARATOR}')") do |separator|
            @separator = separator
          end

          o.on('--remote', "List forks in GitHub") do
            @remote = true
          end

          common_options(o)
        end

        parse_options(opts, argv)
        log.warn "ignoring positional arguments: '#{argv}'" unless argv.empty?

        if not (@remote or @config or @cached)
          #puts opts
          #abort
          @remote = @config = @cached = true
        else
          argv
        end
      end
    end
  end
end
