module GitForks
  module CLI
    class Review
      class Create < Command
        require 'grit'

        def initialize
          super
        end

        def description; "TODO:" end

        def run(*argv)
          optparse(*argv)
          forks = CLI::Review::Poll.new.poll
          create(forks, 'doubleotoo', 'master')
        end

        def create(forks, base_user, base_branch)
          forks.each do |f|
            owner = f['owner']['login']
            if new_refs = f['new-refs']
              new_refs.each do |sha, refs|
                ref = refs.first[:ref]
                branch = ref.split('/').last
                log.info 'Creating pull request: ' +
                  "[from: #{owner}/#{Github.repo}:#{branch} (#{sha[0,8]})] " +
                  "[into: #{base_user}/#{Github.repo}:#{base_branch}]"

                  file_reviewers = reviewers(sha, owner)
                  pull_request(owner, branch, sha, file_reviewers)
              end
            end
          end
        end

        def pull_request(owner, branch, sha, file_reviewers, base = 'master')
          repo  = Github.repo_path
          head  = "#{owner}:#{sha}"
          title = "Merge #{owner}:#{branch} (#{sha[0,8]})"
          body  = "(Automatically generated pull-request.)\n"
          file_reviewers.each {|file, reviewers|
            body << "\n"
            body << reviewers.collect {|r| "@#{r['github-user']}" }.join(' ')
            body << ": please code review #{file}."
          }

          begin
            client = Octokit::Client.new(:login => "doubleotoo", :password => "Jatusa1@github")
            puts client.create_pull_request(repo, base, head, title, body)
            log.info "Created pull request: '#{title}'"
          rescue Octokit::UnprocessableEntity
            log.error "pull request already exists for '#{title}'"
            abort
          end
        end

        # @todo test reviewer == owner
        def reviewers(sha, owner)
          file_reviewers = {}

          grit = Grit::Repo.new('.')
          new_commits = grit.commits_between('origin/master', sha)
          review_commits = new_commits.select { |commit| Github.ignore_commit(grit, commit) == false }
          ignored_commits = new_commits - review_commits

          log.debug "New commits: #{new_commits.size} #{new_commits}"
          log.debug "Ignored commits: #{ignored_commits.size} #{ignored_commits}"

          file_reviewers = Github.get_reviewers_by_file(grit, 'AUTHORS.yml', review_commits)

          # Only need to validate each unique user once.
          reviewers = []
          file_reviewers.each do |f, r|
            reviewers << r.collect {|r| r['github-user'] }
          end
          reviewers = reviewers.flatten.compact.uniq

          Github.validate_reviewers(reviewers)

          # Don't allow self-reviews. Someone else has to review your work!
          file_reviewers.each do |file, reviewers|
            file_reviewers[file] = reviewers.select { |r| r != owner }
          end

          log.debug "Reviewers for new pull request: #{file_reviewers}"

          file_reviewers
        end

        def optparse(*argv)
          reverse = false
          opts = OptionParser.new do |o|
            o.banner = 'Usage: git forks review create [options] [owners ...]'
            o.separator ''
            o.separator description
            o.separator ''
            o.separator 'Example: git forks review create'
            o.separator ''
            o.separator "General options:"

            common_options(o)
          end

          parse_options(opts, argv)
        end
      end
    end
  end
end
