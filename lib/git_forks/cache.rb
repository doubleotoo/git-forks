module GitForks
  module Git
    module Cache # Namespace to manage a Git cache
      class << self
        # Caches +json+ into a top-level JSON +group+
        #
        # @param [String] group the top-level JSON group name
        # @param [String, JSON] json the data to be cached
        # @return [void]
        def cache(group, json)
          save_data({group => json}, GitForks::CACHE_FILE)
        end

        # Gets cached data.
        #
        # @example Gets the entire cached data
        #   get_cached_data
        # @example Gets the cached data for the 'forks' group.
        #   get_cached_data('forks')
        # @return [String,nil]
        def get_cached_data(group=nil)
          data = JSON.parse(File.read(GitForks::CACHE_FILE))
          if group
            data[group]
          else
            data
          end
        end

        # Saves +data+ to +file+.
        #
        # @example Saves a JSON string to file 'cache.json'
        #   save_data('{:forks => [1,2,3]}', 'cache.json')
        # @param [#to_json] data
        # @param [String] file
        # @return [void]
        def save_data(data, file)
          File.open(file, "w+") do |f|
            f.puts data.to_json
          end
        end

        # Gets a cached fork by owner.
        #
        # @example Get the fork data belonging to 'justintoo'
        #   fork('justintoo')
        # @param [String] owner
        # @return [JSON,nil]
        def fork(owner)
          forks = get_cached_data('forks')
          forks.select {|f| f['owner']['login'] == owner }.first
        end
      end
    end
  end
end
