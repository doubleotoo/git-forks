# encoding: utf-8

require 'git_forks/core_ext/hash'

module GitForks
  class ApiFactory

    # Instantiates a new client object with +options+
    def self.new(klass, options={})
      return _create_instance(klass, options) if klass
      raise ArgumentError, 'must provide klass to be instantiated'
    end

  private

    # Passes configuration options to instantiated class
    def self._create_instance(klass, options)
      options.symbolize_keys!
      instance = GitForks.const_get(klass.to_sym).new options
      GitForks.api_client = instance
      instance
    end
  end
end # GitForks
