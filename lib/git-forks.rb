require 'logger'

# JSON is used to cache GitHub API response data.
require 'json'
# Launchy is used in 'browse' to open a browser.
require 'launchy'
# Octokit is used to access GitHub's API.
require 'octokit'
# Time is used to parse time strings from git back into Time objects.
require 'time'

class GitForks

  CACHE_FILE = '.git/forks_cache.json'

  def initialize(args)
    @command = args.shift
    @user, @repo = repo_info
    @args = args
    @updated = false
  end

  def self.start(args)
    GitForks.new(args).run
  end

  def run
    configure
    if @command && self.respond_to?(@command)
      # If the cache file doesn't exist, make sure we run update
      # before any other command. git-forks will otherwise crash
      # with an exception.
      update unless File.exists?(CACHE_FILE) || @command == 'update'

      self.send @command
    elsif %w(-h --help).include?(@command)
      usage
    else
      help
    end
  end

  #-----------------------------------------------------------------------------
  # Logging (stolen from Grit)
  #-----------------------------------------------------------------------------

  class << self
    # Set +debug+ to true to log everything
    attr_accessor :debug

    # The standard +logger+ for debugging - this defaults to a plain STDOUT logger
    attr_accessor :logger
    def log(str)
      logger.debug { str }
    end
  end
  self.debug = false # TODO: add --verbose switch

  @logger ||= ::Logger.new(STDOUT)

  #-----------------------------------------------------------------------------
  # Commands
  #-----------------------------------------------------------------------------

  # Get the latest GitHub data.
  def update
    puts 'Retrieving the latest GitHub data...'

    cache('forks', fetch_fork_info)
    update_branches

    @updated = true
  end

  # Fetch and cache all branches for each fork.
  def update_branches
    forks = get_cached_data('forks')

    forks.each do |fork|
      fork_user = fork['owner']['login']
      GitForks.log "Fetching branches in '#{fork_user}/#{@repo}'" if GitForks.debug

      branches = fetch_fork_branches(fork_user)

      fork['branches'] = branches
    end

    cache('forks', forks)
  end

  # git-fetch from the fork's GitHub repository. (Forces cache update.)
  def fetch
    target_owners = @args

    update if not @updated
    get_cached_data('forks').each do |fork|
      owner = fork['owner']['login']
      if target_owners.empty? or target_owners.include?(owner)
        puts '-' * 80
        puts "Fething Git data from fork '#{owner}/#{@repo}'"
        git("fetch #{github_endpoint}/#{owner}/#{@repo}.git " +
            "+refs/heads/*:refs/forks/#{owner}/#{@repo}/*")
      end
    end
  end

  # List all forks.
  #
  # Example::
  #
  #   --------------------------------------------------------------------------------
  #   Forks of 'doubleotoo/foo/master'
  #
  #   Owner                    Branches    Updated
  #   ------                   --------    -------
  #   justintoo                2           01-May-12
  #   rose-compiler            3           27-Apr-12
  #
  def list
    forks = get_cached_data('forks')
    forks.reverse! if @args.shift == '--reverse'

    output = forks.collect do |f|
      line = ""
      line << l(f['owner']['login'], 25)
      line << l(f['branches'].size, 12)
      line << strftime(clean(f['updated_at']))
    end

    if output.compact.empty?
      puts "No forks of '#{@user}/#{@repo}'"
    else
      puts '-' * 80
      puts "Forks of '#{@user}/#{@repo}'"
      puts
      puts l('Owner', 25) + l('Branches', 12) + 'Updated'
      puts l('------', 25) + l('--------', 12) + '-------'
      puts output.compact
      puts '-' * 80
    end
  end

  # Show details of one fork.
  #
  # Example::
  #
  #   -------------------------------------------------------------------------------
  #   Owner    : justintoo
  #   Created  : 01-May-12
  #   Updated  : 01-May-12
  #   Branches : 2
  #     444a867d338cafc0c82d058b458b4fe268fa14d6 master
  #     14178fe5b204c38650de8ddaf5d9fb80aa834e74 foo
  #
  def show
    owner = @args.shift
    option = @args.shift
    if owner
      if f = fork(owner)
        puts '-' * 80
        puts "Owner    : #{f['owner']['login']}"
        puts "Repo     : #{@repo}"
        puts "Created  : #{strftime(f['created_at'])}"
        puts "Updated  : #{strftime(f['updated_at'])}"
        puts "Branches : #{f['branches'].size}"
        f['branches'].each do |b|
          puts "  #{b['commit']['sha']} #{b['name']}"
        end
        puts '-' * 80
      else
        puts "No such fork: '#{owner}/#{@repo}'. Maybe you need to run git-forks update?"
        puts
        list
      end
    else
        puts "<owner> argument missing"
        puts
        usage
    end
  end

  def browse
    owner = @args.shift
    if owner
      owner, ref = owner.split(':')

      if f = fork(owner)
        url = f['html_url']

        if ref
          if ref.match(/[A-Za-z0-9]{40}/)
            url << "/commits/#{ref}"
          else
            url << "/tree/#{ref}"
          end
        end

        return Launchy.open(url)
      elsif owner == "network"
      else
        puts "No such fork: '#{owner}/#{@repo}'. Maybe you need to run git-forks update?"
        puts
        list
      end
    else
      puts "<owner> argument missing"
      puts
      usage
    end
  end

  def help
    puts "No command: #{@command}"
    puts "Try: browse, fetch, list, show, update"
    puts "or call with '-h' for usage information"
  end

  # Show a quick reference of available commands.
  def usage
    puts 'Usage: git forks <command>'
    puts 'Get GitHub project forks information.'
    puts
    puts 'Available commands:'
    puts '  browse <owner>[:<ref>]  Show fork in web browser.'
    puts '                          <ref> denotes a Git Tree or a Git Commit.'
    puts '  fetch <owners>          git-fetch fork data from GitHub.'
    puts '                          <owners> is a space separate list.'
    puts '                          (Forces cache update.)'
    puts '  list [--reverse]        List all forks.'
    puts '  show <owner>            Show details for a single fork.'
    puts '  update                  Retrieve fork info from GitHub API v3.'
  end

  #-----------------------------------------------------------------------------
  # Cache
  #-----------------------------------------------------------------------------

  def cache(group, json)
    save_data({group => json}, CACHE_FILE)
  end

  # get_cached_data('forks')
  def get_cached_data(group=nil)
    data = JSON.parse(File.read(CACHE_FILE))
    if group
      data[group]
    else
      data
    end
  end

  def save_data(data, file)
    File.open(file, "w+") do |f|
      f.puts data.to_json
    end
  end

  # Get a fork by owner name.
  def fork(owner)
    forks = get_cached_data('forks')
    forks.select {|f| f['owner']['login'] == owner }.first
  end

  #-----------------------------------------------------------------------------
  # GitHub API v3 (using Octokit gem)
  #-----------------------------------------------------------------------------

  def fetch_fork_info
    forks = Octokit.forks("#{@user}/#{@repo}")
  end

  def fetch_fork_branches(fork_user)
    branches = Octokit.branches("#{fork_user}/#{@repo}")
  end

  #-----------------------------------------------------------------------------
  # Git
  #-----------------------------------------------------------------------------

  def git(command)
    `git #{command}`.chomp
  end

  def github_endpoint
    host = git("config --get-all github.host")
    if host.size > 0
      host
    else
      'https://github.com'
    end
  end

  #-----------------------------------------------------------------------------
  # Display Helper Functions
  #-----------------------------------------------------------------------------

  def l(info, size)
    clean(info)[0, size].ljust(size)
  end

  def r(info, size)
    clean(info)[0, size].rjust(size)
  end

  def clean(info)
    info.to_s.gsub("\n", ' ')
  end

  def strftime(time_string)
    Time.parse(time_string).strftime('%d-%b-%y')
  end

  #-----------------------------------------------------------------------------
  private
  #-----------------------------------------------------------------------------

  def configure
    Octokit.configure do |config|
      #config.login = github_login
    end
  end

  #def github_login
  #  git("config --get-all github.user")
  #end

  def repo_info
    c = {}
    config = git('config --list')
    config.split("\n").each do |line|
      k, v = line.split('=')
      c[k] = v
    end
    u = c['remote.origin.url']

    user, proj = github_user_and_proj(u)
    if !(user and proj)
      short, base = github_insteadof_matching(c, u)
      if short and base
        u = u.sub(short, base)
        user, proj = github_user_and_proj(u)
      end
    end
    [user, proj]
  end

  def github_insteadof_matching(c, u)
    first = c.collect {|k,v| [v, /url\.(.*github\.com.*)\.insteadof/.match(k)]}.
              find {|v,m| u.index(v) and m != nil}
    if first
      return first[0], first[1][1]
    end
    return nil, nil
  end

  def github_user_and_proj(u)
    # Trouble getting optional ".git" at end to work, so put that logic below
    m = /github\.com.(.*?)\/(.*)/.match(u)
    if m
      return m[1], m[2].sub(/\.git\Z/, "")
    end
    return nil, nil
  end

end # GitForks
