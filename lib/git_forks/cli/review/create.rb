module GitForks
  module CLI
    class Review
      class Create < Command
        require 'grit'

        def initialize
          super
        end

        def description; "Create GitHub pull requests (runs git-forks-review-poll)" end

        def run(*argv)
          optparse(*argv)
          forks = CLI::Review::Poll.new.poll
          create(forks, 'doubleotoo', 'master').each do |p|
            puts "Created pull request ##{p.number}: " +
                 "#{p.head.repo.owner.login}/#{p.base.repo.name} -> " +
                 "#{Github.repo_path}"
          end
        end

        # @todo: no files modified => no reviewers => test without review
        #   Should we, instead. request any top-level admin to review?
        def create(forks, base_user, base_branch)
          pull_requests = []
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
                  pull_requests << create_pull_request(owner, branch, sha, file_reviewers)
              end
            end
          end
          pull_requests.compact
        end

        # @todo refactor
        # @todo document
        #-------------------------------------------------------------------------
        # Update pull request
        #
        # (This extra step is simply a convenience for code reviewers.)
        #
        # Update the pull request's description with links to each file's diff-url.
        # This allows a code-reviewer to simply click the link to jump to the diff.
        #
        # Example::
        #
        #   Markdown:
        #     @doubleotoo: please code review \
        #     [src/README](https://github.com/doubleotoo/foo/pull/40/files#diff-0).
        #
        #   Visible HTML:
        #     @doubleotoo: please code review src/README.
        #
        #
        # First, we compute the "diff number" (i.e. ../files#diff-<number>) for
        # each file.
        #
        #   Note: This is currently quite hackish. There's no json API that maps
        #   a file to a diff number. So our best bet is to grab the array of
        #   pull_request files and then hope that a file's index in the array is
        #   it's diff number.
        #     I suppose we could just link to the diff page instead...
        #
        #
        # If this update step fails, the pull_request will have a description,
        # requesting developers to code review files--there just won't be any
        # nice HTML links to the diff page.
        #
        # @return [Github::PullRequest,nil]
        #
        #-------------------------------------------------------------------------
        def create_pull_request(owner, branch, sha, file_reviewers, base = 'master')
          head  = "#{owner}:#{sha}"
          title = "Merge #{owner}:#{branch} (#{sha[0,8]})"
          body  = "(Automatically generated pull-request.)\n"
          file_reviewers.each {|file, reviewers|
            body << "\n"
            body << reviewers.collect {|r| "@#{r['github-user']}" }.join(' || ')
            body << ": please code review #{file}."
          }

          github = ::Github.new(:basic_auth => Github.basic_auth)

          begin
            log.debug "base='#{base}'"
            log.debug "head='#{head}'"
            log.debug "title='#{title}'"
            log.debug "body='#{body}'"

            pull_request = github.pull_requests.create_request(
                Github.user,
                Github.repo,
                'title' => title,
                'body'  => body,
                'head'  => head,
                'base'  => base)

            log.info "Created pull request: '#{title}'"
            log.debug "Created pull request: '#{pull_request}'"
          rescue ::Github::Error::UnprocessableEntity
            log.warn "pull request already exists for '#{title}'"
            return
          rescue ::Github::Error::Unauthorized
            log.error 'Authorization failed. Please check your GitHub credentials.'
            abort
          end

          #---------------------------------------------------------------------
          # UPDATE
          #---------------------------------------------------------------------

          pull_request_file_diff_number = {}
          i=0; github.pull_requests.files(
            Github.user,
            Github.repo,
            pull_request.number).each_page do |page|
              page.each do |file|
                pull_request_file_diff_number[file.filename] = i
                i += 1
              end
            end

          #---------------------------------
          # Pull request description body
          #
          #   + With diff-links for files
          #---------------------------------
          body = "(Automatically generated pull-request.)\n"
          file_reviewers.each do |file, reviewers|
            diff_number = pull_request_file_diff_number[file]
            diff_url = "#{pull_request.html_url}/files#diff-#{diff_number}"
            diff_link = "[#{file}](#{diff_url})" # markdown [name](anchor)
            log.debug "diff_link='#{diff_link}' for #{file}"

            body << "\n"
            body << reviewers.collect {|r| "@#{r['github-user']}" }.join(' || ')
            body << ": please code review #{diff_link}."

            raise "diff_number is nil for #{file}!" if diff_number.nil?
          end

          begin
            github.pull_requests.update_request(
                Github.user,
                Github.repo,
                pull_request.number,
                'body' => body
            )
          rescue ::Github::Error::Unauthorized
            log.error 'Authorization failed. Please check your GitHub credentials.'
            abort
          end
          log.debug "Updated GitHub::PullRequest with diff-links for files: #{pull_request.to_json}"
          pull_request
        end # create_pull_request

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
