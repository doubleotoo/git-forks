module GitForks
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
