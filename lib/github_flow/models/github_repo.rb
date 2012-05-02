module GithubFlow
  module Models
    require 'active_record'

    class GithubRepo < ActiveRecord::Base
      self.table_name = 'github_repo'

      has_many :branches, :class_name => 'GithubRepoBranch'
      has_many :pull_requests, :class_name => 'GithubRepoPullRequest', :foreign_key => 'head_github_repo_id'

      def path
        "#{self.user}/#{self.name}"
      end

      def to_s
        "<GithubRepo:#{path}:{:branches => '#{branches}', :pull_requests => '#{pull_requests}'}>"
      end
    end # GithubRepo
  end # Models
end # GithubFlow

