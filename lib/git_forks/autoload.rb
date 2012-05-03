# @private
def __p(path) File.join(GitForks::ROOT, 'git_forks', *path.split('/')); end

module GitForks
  module CLI # Namespace for command-line interface components
    autoload :Command,        __p('cli/command')
    autoload :CommandParser,  __p('cli/command_parser')
    autoload :Browse,         __p('cli/browse')
    autoload :Config,         __p('cli/config')
    autoload :Fetch,          __p('cli/fetch')
    autoload :Help,           __p('cli/help')
    autoload :List,           __p('cli/list')
    autoload :Show,           __p('cli/show')
    autoload :Update,         __p('cli/update')
  end

  autoload :Logger,  __p('logging')
end

undef __p
