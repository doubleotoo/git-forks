# encoding: utf-8

module GithubFlow
  module Configuration

    VALID_OPTIONS_KEYS = [
    ].freeze

    attr_accessor *VALID_OPTIONS_KEYS

    # Convenience method to allow for global setting of configuration options
    def configure
      yield self
    end

    def self.extended(base)
      base.set_defaults
    end

    def options
      options = {}
      VALID_OPTIONS_KEYS.each { |k| options[k] = send(k) }
      options
    end

    def set_defaults
      self
    end

  end # Configuration
end # GithubFlow
