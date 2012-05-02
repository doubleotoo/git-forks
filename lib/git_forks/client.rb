# encoding: utf-8

module GitForks
  class Client

    def initialize(options = {}, &block)
      options = GitForks.options.merge(options)
      self.instance_eval(&block) if block_given?
    end

    def gists(options = {})
      @gists ||= ApiFactory.new 'Gists', options
    end

  end # Client
end # GitForks
