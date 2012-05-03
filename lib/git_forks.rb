module GitForks
  VERSION = "0.0.1"

  # The root path for GitForks source
  ROOT = File.expand_path(File.dirname(__FILE__))

  # The GitHub fork's cache
  CACHE_FILE      = '.git/forks_cache.json'
  CONFIG_SECTION  = 'github.forks.owner'

  # Load Ruby core extension classes
  Dir.glob(File.join(GitForks::ROOT, 'git_forks', 'core_ext', '*.rb')).each do |file|
    require file
  end

  ['autoload', 'git', 'github', 'globals'].each do |file|
    require File.join(GitForks::ROOT, 'git_forks', file)
  end
end # GitForks
