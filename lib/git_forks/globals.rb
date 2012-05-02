# @group Global Convenience Methods

# The global {GitForks::Logger} instance
#
# @return [GitForks::Logger] the global {GitForks::Logger} instance
# @see GitForks::Logger
def log
  GitForks::Logger.instance
end
