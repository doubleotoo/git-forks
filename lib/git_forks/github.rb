require 'github_api'

module GitForks
  # @todo validate repository on initialization of application
  module Github # Namespace for communicating with the GitHub API v3
    class << self
      #def login
      #  Git.run("config --get-all github.user")
      #end

      def repo_info
        c = {}
        config = Git.run('config --list')
        config.split("\n").each do |line|
          k, v = line.split('=')
          c[k] = v
        end
        u = c['remote.origin.url']

        if u.nil?
          log.error 'Your Git repository has no remote.origin.url'
          abort
        end

        user, proj = user_and_proj(u)
        if !(user and proj)
          short, base = insteadof_matching(c, u)
          if short and base
            u = u.sub(short, base)
            user, proj = user_and_proj(u)
          end
        end
        {
          :user => user,
          :name => proj
        }
      end

      def user; repo_info[:user] end
      def repo; repo_info[:name] end
      def repo_path; "#{user}/#{repo}" end

      def user_and_proj(u)
        # Trouble getting optional ".git" at end to work, so put that logic below
        m = /github\.com.(.*?)\/(.*)/.match(u)
        if m
          return m[1], m[2].sub(/\.git\Z/, "")
        end
        return nil, nil
      end

      def endpoint
        host = Git.run("config --get-all github.host")
        if host.size > 0
          host
        else
          'https://github.com'
        end
      end

      def network_url
        "#{endpoint}/#{repo_path}/network"
      end

      def forks
        forks = Github.repos.forks(user, repo).each_page.collect {|page|
          page.collect {|branch| branch }
        }.flatten
        log.debug "Fetched forks from '#{repo_path}': '#{JSON.pretty_generate(forks)}'"
        forks
      end

      def branches(fork_owner)
        repo_path = "#{fork_owner}/#{repo}"
        branches = Github.repos.branches(fork_owner, repo).each_page.collect {|page|
          page.collect {|branch| branch }
        }.flatten

        log.debug "Fetched branches from '#{repo_path}': '#{JSON.pretty_generate(branches)}'"
        branches
      end

      def fetch_refs(owner)
        Git.fetch_refs("#{endpoint}/#{owner}/#{repo}.git", "forks/#{owner}")
      end

      # BEGIN UTILITIES

      # TODO:
      def in_master?(grit, commit)
        grit.git.branch({ :contains => commit.sha }).match(/\* master/)
      end

      # TODO: better way to check for merge commit?
      def merge_commit?(commit)
        commit.message.match(/^Merge branch/)
      end

      # ignore_commit
      #
      #   Filter commits to identify ones that require code review.
      #
      #   +grit+
      #   +commit+
      #
      #   Returns true if the commit should not be ignored. This does not imply
      #   that the commit needs to be code reviewed.
      #
      def ignore_commit(grit, commit)
        ignore = false

        if in_master?(grit, commit)
          #
          # Skip: commit merged from origin/master.
          #
          log.debug "#{commit.sha} is already in origin/master."
          ignore = true
        elsif merge_commit?(commit)
          #
          # Skip: merge commits
          #
          # TODO: unreliable check for regex in commit message.
          #       Loophole scenario: user explicitly adds merge
          #       message to commit to bypass review.
          #
          log.debug "#{commit.sha} is a merge commit."
          ignore = true
        elsif commit.stats.files.empty?
          #
          # Skip: empty commit (no files modified)
          #
          log.debug "#{commit.sha} has no file modifications (empty commit)."
          ignore = true
        end

        return ignore
      end

      # get_modified_files
      #
      # +commits+
      #
      def get_modified_files(commits)
        commits.collect {|commit|
          commit.stats.files.collect {|filename, adds, deletes, total| filename}
        }.flatten.compact.uniq
      end

      ## get_closest_file
      #
      # Find the closest +filename+ starting at +path+.
      #
      # Example::
      #
      #   Given this directory structure:
      #
      #     ROOT/
      #       TARGET.txt
      #      subdir1/
      #        TARGET.txt
      #      subdir2/
      #
      #   get_closest_file(.., 'TARGET.txt', 'subdir2') => ROOT/subdir1/TARGET.txt
      #   get_closest_file(.., 'TARGET.txt', 'subdir2') => ROOT/TARGET.txt
      #
      # TODO: return hash { :path_string => '', :grit_tree => '' }
      # TODO: raise error if not found (instead of returning nil)?
      #
      # Returns a hash:
      #
      #   {
      #     :dirname => "relative/path/to/dir",
      #     :tree => :+Grit::Tree+
      #   }
      #
      def get_closest_file(commit, filename, path)
        dirs = File.dirname(path).split(File::SEPARATOR)

        while not dirs.empty?
          currentpath = dirs.join(File::SEPARATOR)

          log.debug "Checking #{currentpath}/ for #{filename}"

          tree = commit.tree / currentpath
          tree = tree / filename if tree
          if tree.nil? # path/to/filename does not exist
            dirs.pop
          else
            return { :dirname => currentpath, :tree => tree }
          end
        end

        # Tree could be nil if no ROOT/filename exists.
        { :dirname => '', :tree => commit.tree / filename }
      end # get_closest_file

      # get_reviewers_for_file
      #
      def get_reviewers_for_file(commit, authors_file, file)
        reviewers = {}
        yamldata = nil

        log.debug "Locating closest file=#{authors_file} for #{commit.id_abbrev}:#{file}"
        grit_authors_file = get_closest_file(commit, authors_file, file)
        dirname = grit_authors_file[:dirname]
        tree = grit_authors_file[:tree]

        # Parse +authors_file+ (YAML) for +file+ code reviewers.
        if tree.nil?
          raise "The closest authors_file=#{authors_file} to file=#{file} is nil!"
        else
          log.debug "Located file=#{File.join(dirname, authors_file)} as the closest " +
                         "file=#{authors_file} for #{commit.id_abbrev}:#{file}"

          yaml = YAML.load(tree.data)
          reviewers = yaml['code-reviewers']
        end
      end

      # get_reviewers
      #
      # +grit+
      # +authors_filename+ A YAML file.
      # +commits+
      #
      # Get a list of code reviewers for a collection of commits,
      # from the meta data in the HEAD of the repository.
      #
      # Returns a Hash:
      #
      #   {
      #     :file => [reviewer1, reviewer2, ..],
      #     ...
      #   }
      #
      def get_reviewers_by_file(grit, authors_file, commits)
        files       = get_modified_files(commits)
        head_commit = grit.commits.first

        reviewers = {}
        files.each do |file|
          file_reviewers = get_reviewers_for_file(head_commit, authors_file, file)
          if file_reviewers.nil? or file_reviewers.empty?
            raise "file_reviewers=#{file_reviewers} (nil/empty) for file=#{file}"
          else
            log.debug "Code reviewers for #{head_commit.id_abbrev}:#{file}: #{file_reviewers}"
            reviewers[file] = file_reviewers
          end
        end

        log.debug "Code reviewers (by file) for commit=#{head_commit.id_abbrev}: #{reviewers}"
        reviewers
      end # get_reviewers

      # @todo raise error instead of aborting?
      def validate_reviewers(reviewers)
        reviewers.each do |reviewer|
          log.debug "Validating GitHub account '#{reviewer}'"

          begin
            ::Github.users.get_user(reviewer)
          rescue ::Github::Error::NotFound
            log.error "Invalid GitHub user: #{reviewer}"
            abort
          end
        end
      end # validate_reviewers

      private

      def insteadof_matching(c, u)
        first = c.collect {|k,v| [v, /url\.(.*github\.com.*)\.insteadof/.match(k)]}.
                  find {|v,m| u.index(v) and m != nil}
        if first
          return first[0], first[1][1]
        end
        return nil, nil
      end
    end
  end # Github
end # GitForks
