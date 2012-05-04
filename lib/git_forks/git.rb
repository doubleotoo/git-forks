require 'json'

module GitForks
  # @todo refactor into reusable component
  module Git # Namespace for managing Git repository
    class << self
      def git(command)
        `git #{command}`.chomp
      end
      alias :run :git

      # Removes a group of git-refs under +refs/forks/+.
      #
      # @example Removes the +refs/forks/rose-compiler/+ directory
      #   git_remove_ref('rose-compiler')
      # @param [String] ref is a git-ref path
      # @return [void]
      def remove_refs(ref)
        refdir = "refs/forks/#{group}" # to be safe, only allow groups under
                                       # our +forks+ namespace
        gitdir = ".git/#{refdir}"

        if Dir.exists?(gitdir)
          Dir.foreach(gitdir) do |ref|
            next if ref == '.' or ref == '..'
            # delete each individual ref first
            git("update-ref -d #{refdir}/#{ref}")
          end

          # delete the ref directory
          git("update-ref -d #{refdir}")
        end
      end
    end # class << self

    # @todo cache file may not exist
    #
    # @todo refactor into a reusable component where the underlying
    #   cache mechanism is transparent, e.g. git-config, file, database
    module Cache # Namespace to manage a Git cache
      class << self
        # Caches +json+ into a top-level JSON +group+
        #
        # @param [String] group the top-level JSON group name
        # @param [String, JSON] the json the data to be cached
        # @param [String] the cache file name
        # @return [void]
        def cache(user_options = {})
          options = {
            :file => GitForks::CACHE_FILE
          }.merge(user_options).freeze
          raise 'Missing required option :json' if not options.has_key?(:json)
          raise 'Missing required option :group' if not options.has_key?(:group)
          #-----------------------------------------------------------------------------
          write_file({options[:group] => options[:json]}, options[:file])
        end
        alias :save  :cache
        alias :write :cache

        # Gets cached data.
        #
        # @example Gets the entire cached data
        #   get_cached_data
        # @example Gets the cached data for the 'forks' group.
        #   get_cached_data('forks')
        # @param [Hash] user_options
        #   +:file+ (optional) the cache file name
        # @return [String,nil]
        def get_group(user_options = {})
          options = {
            :group => nil,
            :file => GitForks::CACHE_FILE
          }.merge(user_options).freeze
          #-----------------------------------------------------------------------------
          data = JSON.parse(File.read(options[:file]))
          if group = options[:group]
            data[group]
          else
            data
          end
        end

        # Gets a cached fork by owner.
        #
        # @example Get the fork data belonging to 'justintoo'
        #   fork('justintoo')
        # @param [String] owner
        # @return [JSON,nil]
        def get_fork(owner)
          forks = get_forks
          forks.select {|f| f['owner']['login'] == owner }.compact.first
        end

        # Gets all cached forks
        #
        # @return [JSON, nil]
        def get_forks
          forks = get_group(:group => 'forks')
        end

        # Gets all cached forks
        #
        # @return [Array<String>, nil]
        def get_fork_owners
          forks = get_forks
          forks.collect {|f| f['owner']['login'] }
        end

        private

        # Saves +data+ to +file+.
        #
        # @example Saves a JSON string to file 'cache.json'
        #   save_data('{:forks => [1,2,3]}', 'cache.json')
        # @param [#to_json] data
        # @param [String] file name
        # @return [void]
        def write_file(data, file)
          File.open(file, "w+") do |f|
            log.debug "Writing data to file='#{file}', data='#{data.to_json}'"
            f.puts data.to_json
          end
        end
      end
    end

    module Config # Namespace to manage git-config
      class << self
        # Gets all values for a given +section+
        #
        # @todo allow array for section: %w(github forks owner)
        #
        # @example Gets all the values for 'github.forks.owner'
        #   get_all('github.forks.owner')
        # @param [String] section the git-config section
        # @return [Array<String>]
        def get_all(section)
          Git.run("config --get-all #{section}").split("\n")
        end

        # Gets one value for a given +section+
        #
        # @todo allow array for section: %w(github forks owner)
        #
        # @example Gets the value for 'github.forks.owner'
        #   get('github.forks.owner')
        # @param [String] section the git-config section
        # @param [String] value (optional) the specific value.
        # @return [String,nil]
        def get(section, value=nil)
          if value
            Git.run("config --get-all #{section} \"^#{value}$\"").split("\n").first
          else
            Git.run("config --get-all #{section}").split("\n").first
          end
        end

        def add(section, value)
          Git.run("config --add #{section} #{value}")
        end

        def remove(section, owner)
          Git.git("config --unset #{section} \"^#{owner}$\"")
        end
      end
    end # Config
  end # Git
end # GitForks
