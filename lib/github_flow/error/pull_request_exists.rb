module GithubFlow
  module Error
    extend AutoloadHelper

    class PullRequestExistsError < GithubFlowError
      REGEX = Regexp.compile('base A pull request already exists for (?<head>.+):(?<branch_or_git_ref>.+)')

      def initialize(response_message)
        super(message)
        @match = response_message[:body].match(REGEX)
      end

      def matches?
        return( not @match.nil? )
      end

      def to_s
        @match
      end
    end
  end # Error
end # GithubFlow
