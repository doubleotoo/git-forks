module GitForks
  module CLI
    class Review
      class Poll < Command
        # @return [String] optional list of specific forks to check
        attr_accessor :targets

        # @return [Boolean] if we should poll for reviewed pull requests
        attr_accessor :reviewed

        def initialize
          super
        end

        def description; "Poll GitHub repositories for new/updated branches (fetches git-refs)" end

        # @reviewed format:
        #
        #   <base_user>/<repo> #<pull-request-number>
        #
        #
        def run(*argv)
          optparse(*argv)
          if @reviewed
            reviewed = get_reviewed_pull_requests
            reviewed.each do |p|
              puts "#{Github.repo_path} ##{p.number}"
            end
          else
            @targets = Git::Cache.get_forks.collect {|f| f['owner']['login']} if @targets.empty?
            forks = poll(@targets)
            forks.each do |f|
              if new_refs = f['new-refs']
                new_refs.each do |sha, refs|
                  puts "#{f['owner']['login']}:#{sha[0,8]} (#{refs.collect {|r| r[:ref]}.join(', ')})"
                end
              end
            end
          end
        end

        def poll(targets = [])
          CLI::Fetch::Refs.new.fetch(targets)

          forks = Git::Cache.get_forks
          forks.select do |f|
            owner = f['owner']['login']
            log.info "Polling #{owner}/#{Github.repo}"

            refs = Git.fork_refs(owner)
            refs.each do |r|
              sha = r[:sha]
              ref = r[:ref]
              log.debug "#{owner}:#{sha} #{ref}"

              if Git.not_merged?(sha, 'origin/master')
                log.info "#{owner}:#{ref} (#{sha[0,8]}) (NEW)"
                f['new-refs'] ||= {}
                f['new-refs'][sha] ||= []
                f['new-refs'][sha] << r
                true
              else
                log.info "#{owner}:#{ref} (#{sha[0,8]}) already integrated"
                false
              end
            end
          end
        end

        # get_reviewed_pull_requests
        #
        # TODO: regular expressions need to be made more robust
        # TODO: (policy) if a pull_request wasn't automatically created, there won't be
        #                any @reviewers in the pull_request description. In general,
        #                this means that a user manually submitted a pull_request. In
        #                this case, how do we want to validate @user reviewed XXX
        #                comments?
        #
        #                   * No "@reviewer review request" lines in the description,
        #                     then => accept any @reviewed comment line by:
        #
        #                       1. repository collaborators or "Admin" users that we
        #                          track in some other data store.
        #
        def get_reviewed_pull_requests(github = ::Github.new)
          reviewed = []

          pulls = github.pull_requests.requests(Github.user, Github.repo)
          pulls.reverse_each do |p|
            log.debug "Checking if pull request " +
              "'#{Github.user}/#{Github.repo}##{p.number}' " +
              "has been code reviewed."

            # Extract all the automatically generated lines pertaining to code review.
            review_lines = []
            file_reviewers = {}
            request_description = p.body
            request_description.each_line do |line|
              # TODO: make the message a configuration
              if match = line.match(/^@(?<users>.+): please code review (?<file>.+).*/)
                users = match['users'].split('||').collect {|u| u.strip.gsub('@', '') }
                file = match['file'].strip
                # file could contain Markdown HTML links: [name](anchor)
                if match = file.match(/\[(?<file>.+)\]\((?<anchor>.+)\)/)
                  file = match['file'].strip
                  anchor = match['anchor'].strip
                end

                review_lines << line

                file_reviewers[file] ||= []
                file_reviewers[file] << users
                file_reviewers[file].flatten!
              end
            end

            log.debug "Code review request lines for pull request " +
              "'#{Github.user}/#{Github.repo}##{p.number}': #{review_lines}"

            file_reviewers.each do |file, reviewers|
              log.debug "Pull request " +
                "'#{Github.user}/#{Github.repo}##{p.number}' " +
                "requests '#{reviewers}' to code review file='#{file}'"
            end

            github.issues.comments(Github.user, Github.repo, p.number).each_page do |page|
              page.each do |c|
                c_id      = c.id
                c_author  = c.user.login
                c_body    = c.body

                if c_body and match = c_body.match(/@(?<user>#{Github.user}).*reviewed (?<file>[^ ]+)/)
                  user = match['user'].strip
                  file = match['file'].strip

                  log.debug "Detected code reviewed line for file='#{file}' in " +
                    "comment id='#{c_id}' authored by '#{c_author}' for " +
                    "pull request '#{Github.user}/#{Github.repo}##{p.number}'"

                  # file could contain Markdown HTML links: [name](anchor)
                  if match = file.match(/\[(?<file>.+)\]\((?<anchor>.+)\)/)
                    file = match['file'].strip
                    anchor = match['anchor'].strip
                  end

                  # This code reviewer is one of the people in the code review request list.
                  reviewers = file_reviewers[file]
                  if reviewers.nil? or reviewers.empty?
                    # TODO: don't post multiple times if a comment
                    #       already exists!
                    log.debug "No reviewers for '#{file}' (#{file_reviewers}). Unknown file?"
                    github = ::Github.new(:basic_auth => Github.basic_auth)
                    github.issues.create_comment(Github.user, Github.repo, p.number,
                        "body" => "@#{c_author}: unknown file '#{file}'")
                  else
                    if reviewers.include?(c_author)
                      log.debug "User '#{c_author}' has code reviewed file='#{file}' for " +
                        "pull request '#{Github.user}/#{Github.repo}##{p.number}' " +
                        "as requested."

                      file_reviewers.delete(file) # file has been reviewed
                    else
                      # TODO: add comment?
                      log.debug "User '#{c_author}' was not requested to code review file='#{file}' " +
                        "for pull request '#{Github.user}/#{Github.repo}##{p.number}'"
                    end
                  end
                end
              end
            end # github.issues.comments.each_page

            outstanding_file_reviews = file_reviewers

            if outstanding_file_reviews.empty?
              log.debug "Pull request " +
                "'#{Github.user}/#{Github.repo}##{p.number}' " +
                "has been code reviewed. Ready for testing!"
              reviewed << p
            else
              log.debug "Pull request " +
                "'#{Github.user}/#{Github.repo}##{p.number}' " +
                "has ('#{outstanding_file_reviews.size}') outstanding code review requests."

                outstanding_file_reviews.each do |file, reviewers|
                  log.debug "Pull request " +
                    "'#{Github.user}/#{Github.repo}##{p.number}' " +
                    "still requires '#{reviewers}' to code review file='#{file}'"
                end
            end
          end # pulls.reverse_each
          reviewed
        end # get_reviewed_pull_requests

        def optparse(*argv)
          reverse = false
          opts = OptionParser.new do |o|
            o.banner = 'Usage: git forks review poll [options] [owners ...]'
            o.separator ''
            o.separator description
            o.separator ''
            o.separator 'Example: git forks review poll'
            o.separator ''
            o.separator "General options:"

            o.on('--reviewed', 'Poll pull requests that are fully reviewed') do
              @reviewed = true
            end

            common_options(o)
          end

          parse_options(opts, argv)
          @targets = argv.uniq
        end
      end
    end
  end
end
