# Octokit is used to access GitHub's API.
require 'octokit'

module GitForks
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

      def forks
        forks = Octokit.forks(repo_path)
        log.debug "Fetched forks from '#{repo_path}': '#{JSON.pretty_generate(forks)}'"
        forks
      end

      def branches(fork_owner)
        repo_path = "#{fork_owner}/#{repo}"
        branches = Octokit.branches(repo_path)

        log.debug "Fetched branches from '#{repo_path}': '#{JSON.pretty_generate(branches)}'"
        branches
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
