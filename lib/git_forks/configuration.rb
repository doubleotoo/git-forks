# encoding: utf-8

module GitForks
  module Configuration

    VALID_OPTIONS_KEYS = [
      :endpoint,
      :login,
      :password
    ].freeze

    # By default, don't set a user login name
    DEFAULT_LOGIN = nil

    # By default, don't set a user password
    DEFAULT_PASSWORD = nil

    # The endpoint used to connect to GitHub if none is set
    DEFAULT_ENDPOINT = 'https://api.github.com'.freeze

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
      self.endpoint           = DEFAULT_ENDPOINT
      self.login              = DEFAULT_LOGIN
      self.password           = DEFAULT_PASSWORD
      self
    end

  end # Configuration
end # GitForks
