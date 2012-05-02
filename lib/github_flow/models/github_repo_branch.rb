module GithubFlow
  module Models
    require 'active_record'

    class GithubRepoBranch < ActiveRecord::Base
      self.table_name = 'github_repo_branch'

      belongs_to :github_repo

      # Does not work... #{self.github_repo}
      def to_s
        "<GithubRepoBranch:#{self.github_repo.path}:#{self.name}:#{self.sha}>"
      end
    end # GithubRepoBranch
  end # Models
end # GithubFlow

