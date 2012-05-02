module GithubFlow
  module Error
    extend AutoloadHelper

    class GithubFlowError < StandardError
      def initialize(message)
        super(message)
      end
    end

  end # Error
end # GithubFlow

%w[
  pull_request_exists
].each do |error|
  require "github_flow/error/#{error}"
end
