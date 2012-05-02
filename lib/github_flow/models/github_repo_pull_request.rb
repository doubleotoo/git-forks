module GithubFlow
  module Models
    require 'active_record'

    class GithubRepoPullRequest < ActiveRecord::Base
      self.table_name = 'github_repo_pull_request'

      belongs_to :head_github_repo, :class_name => 'GithubRepo'

      # Does not work... #{self.github_repo}
      def to_s
        "<GithubRepoPullRequest(##{self.issue_number}):#{self.base_github_repo_path}<-#{self.head_github_repo.path}>"
      end
    end # GithubRepoPullRequest
  end # Models
end # GithubFlow

