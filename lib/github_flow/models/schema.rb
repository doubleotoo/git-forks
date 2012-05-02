module GithubFlow
  module Models
    require 'logger'
    require 'active_record'

    class Schema
      def initialize(adapter='sqlite3', database=':memory:', force=true, logger=Logger.new(STDERR))
        @adapter    = adapter
        @database   = database
        @force      = force
        @logger     = logger

        ActiveRecord::Base.logger = @logger

        ActiveRecord::Base.establish_connection(
            :adapter  => @adapter,
            :database => @database
        )

         # ActiveRecord::Schema.define do
         #     create_table :github_repo, :force => @force do |table|
         #         table.column :user,
         #           :string,
         #           :presence => true
         #         table.column :name,
         #           :string,
         #           :presence => true,
         #     end # github_repo

         #     create_table :github_repo_branch, :force => @force do |table|
         #         table.column :github_repo_id,
         #           :integer,
         #           :presence => true
         #         table.column :name,
         #           :string,
         #           :presence => true
         #         table.column :sha,
         #           :string,
         #           :presence => true
         #     end # github_repo_branch

         #     create_table :github_repo_pull_request, :force => @force do |table|
         #         table.column :head_github_repo_id,
         #           :integer,
         #           :presence => true
         #         table.column :base_github_repo_path,
         #           :string,
         #           :presence => true
         #         table.column :base_sha,
         #           :string,
         #           :presence => true
         #         table.column :head_sha,
         #           :string,
         #           :presence => true
         #         table.column :issue_number,
         #           :integer,
         #           :presence => true
         #     end # github_repo_pull_request
        # end
      end
    end # Schema
  end # Models
end # GithubFlow
