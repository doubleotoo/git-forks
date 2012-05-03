require 'octokit'

module GitForks
  module Github # Namespace for communicating with the GitHub API v3
    class << self
      #def github_login
      #  git("config --get-all github.user")
      #end

      def user; repo_info[:user] end
      def repo; repo_info[:name] end

      def repo_info
        c = {}
        config = git('config --list')
        config.split("\n").each do |line|
          k, v = line.split('=')
          c[k] = v
        end
        u = c['remote.origin.url']

        user, proj = github_user_and_proj(u)
        if !(user and proj)
          short, base = insteadof_matching(c, u)
          if short and base
            u = u.sub(short, base)
            user, proj = github_user_and_proj(u)
          end
        end
        {
          :user => user,
          :name => proj
        }
      end

      def user_and_proj(u)
        # Trouble getting optional ".git" at end to work, so put that logic below
        m = /github\.com.(.*?)\/(.*)/.match(u)
        if m
          return m[1], m[2].sub(/\.git\Z/, "")
        end
        return nil, nil
      end

      def endpoint
        host = git("config --get-all github.host")
        if host.size > 0
          host
        else
          'https://github.com'
        end
      end

      def fetch_fork_info
        targets = config_get_forks # optional fork targets
        forks = Octokit.forks("#{@user}/#{@repo}").select {|f|
          targets.empty? or targets.include?(f.owner.login)
        }

        unless targets.empty?
          owners = forks.collect {|f| f['owner']['login'] }
          if not (dne = targets - owners).empty?
            dne.each do |owner|
              puts "WARNING: #{owner}/#{@repo} does not exist."
              # `git forks fetch <dne>` will report <dne>
              # as not being in the forks whitelist. It is
              # in the list, but it doesn't exist in GitHub.
              #
              # Hopefully, this WARNING message will help.
            end
          end
        end

        forks
      end

      def fetch_fork_branches(fork_user)
        branches = Octokit.branches("#{fork_user}/#{@repo}")
      end
    end

    private

      def insteadof_matching(c, u)
        first = c.collect {|k,v| [v, /url\.(.*github\.com.*)\.insteadof/.match(k)]}.
                  find {|v,m| u.index(v) and m != nil}
        if first
          return first[0], first[1][1]
        end
        return nil, nil
      end
  end # Github
end # GitForks
