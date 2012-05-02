module GithubFlow
  module Models
    extend AutoloadHelper

    autoload_all 'github_flow/models',
      :Schema                   => 'schema',
      :GithubRepo               => 'github_repo',
      :GithubRepoBranch         => 'github_repo_branch',
      :GithubRepoPullRequest    => 'github_repo_pull_request'
  end # Models
end # GithubFlow
