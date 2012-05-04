# @private
def __p(path) File.join(GitForks::ROOT, 'git_forks', *path.split('/')); end

module GitForks
  module CLI # Namespace for command-line interface components
    autoload :Command,        __p('cli/command')
    autoload :CommandParser,  __p('cli/command_parser')
    autoload :Browse,         __p('cli/browse')

    autoload :Config,         __p('cli/config')
    class Config
      autoload :Add,          __p('cli/config/add')
      autoload :Check,        __p('cli/config/check')
      autoload :Get,          __p('cli/config/get')
      autoload :Help,         __p('cli/config/help')
      autoload :List,         __p('cli/config/list')
      autoload :Remove,       __p('cli/config/remove')
    end

    autoload :Fetch,          __p('cli/fetch')
    class Fetch
      autoload :Info,         __p('cli/fetch/info')
      autoload :Refs,         __p('cli/fetch/refs')
      autoload :Help,         __p('cli/fetch/help')
    end

    autoload :Help,           __p('cli/help')
    autoload :List,           __p('cli/list')
    autoload :Show,           __p('cli/show')
    autoload :Update,         __p('cli/update')
  end

  autoload :Logger,  __p('logging')
end

undef __p
