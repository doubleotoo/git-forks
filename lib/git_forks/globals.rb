# @group Global Convenience Methods

# The global {GitForks::Logger} instance
#
# @return [GitForks::Logger] the global {GitForks::Logger} instance
# @see GitForks::Logger
def log
  GitForks::Logger.instance
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

# All calls to `puts` in CLI commands are paged,
# git-style.
#
# @todo move out of global scope
# @todo add '--no-pager' option
def puts(*args)
  page_stdout
  super
end

def windows?
  require 'rbconfig'
  RbConfig::CONFIG['host_os'] =~ /msdos|mswin|djgpp|mingw|windows/
end

# https://github.com/defunkt/hub/blob/master/lib/hub/commands.rb
# http://nex-3.com/posts/73-git-style-automatic-paging-in-ruby
def page_stdout
  return if not $stdout.tty? or windows?

  read, write = IO.pipe

  if Kernel.fork
    # Parent process, become pager
    $stdin.reopen(read)
    read.close
    write.close

    # Don't page if the input is short enough
    ENV['LESS'] = 'FSRX'

    # Wait until we have input before we start the pager
    Kernel.select [STDIN]

    pager = ENV['GIT_PAGER'] ||
      `git config --get-all core.pager`.split.first || ENV['PAGER'] ||
      'less -isr'

    pager = 'cat' if pager.empty?
    exec pager rescue exec "/bin/sh", "-c", pager
  else
    # Child process
    $stdout.reopen(write)
    $stderr.reopen(write) if $stderr.tty?
    read.close
    write.close
  end
end
