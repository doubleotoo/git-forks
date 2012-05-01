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
    @branch_pattern = branch_pattern
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
  # Commands
  #-----------------------------------------------------------------------------

  # Get the latest GitHub data.
  def update
    cache('forks', fetch_fork_info)
    update_branches
  end

  # Fetch and cache all branches for each fork.
  def update_branches(pattern=nil)
    pattern ||= @branch_pattern
    forks = get_cached_data('forks')

    forks.each do |fork|
      fork_user = fork['owner']['login']
      puts "Checking for new branches matching '#{pattern}' in '#{fork_user}/#{@repo}'"

      branches = fetch_fork_branches(fork_user, pattern)

      fork['branches'] = branches
    end

    cache('forks', forks)
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

  # Show a quick reference of available commands.
  def usage
    puts 'Usage: git forks <command>'
    puts 'Get GitHub project forks information.'
    puts
    puts 'Available commands:'
    puts '  list [--reverse]        List all forks.'
    puts '  show <owner>            Show details for a single fork.'
    puts '  update                  Retrieve fork info from GitHub API v3.'
    puts '  browse <owner>[:<ref>]  Show fork in web browser.'
    puts '                          <ref> denotes a Git Tree or a Git Commit.'
    puts
    puts 'Git configurations:'
    puts '  github.forks.branchpattern        Only grab branches matching this Ruby Regexp.'
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

  def fetch_fork_branches(fork_user, pattern)
    pattern ||= @branch_pattern
    branches = Octokit.branches("#{fork_user}/#{@repo}")
                  .select {|b| not b.name.match(pattern).nil? }
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

  def help
    puts "No command: #{@command}"
    puts "Try: browse, list, show, update"
    puts "or call with '-h' for usage information"
  end

  def configure
    Octokit.configure do |config|
      #config.login = github_login
    end
  end

  #def github_login
  #  git("config --get-all github.user")
  #end

  def branch_pattern
    patterns = git("config --get-all github.forks.branchpattern")
    if patterns.empty?
      Regexp.new(/.+/) # match anything
    else
      Regexp.new(patterns.gsub("\n", "|"))
    end
  end

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

  def git(command)
    `git #{command}`.chomp
  end

end # GitForks
