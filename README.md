Design and skeleton thanks to [schacon/git-pulls](https://github.com/schacon/git-pulls) and [b4mboo/git-review](https://github.com/b4mboo/git-review).

git-forks
----------

Get info about a GitHub project's forks.

    $ git forks update
    Checking for new branches matching '(?-mix:.+)' in 'justintoo/foo'
    Checking for new branches matching '(?-mix:.+)' in 'rose-compiler/foo'

    $ git forks list
    --------------------------------------------------------------------------------
    Forks of 'doubleotoo/foo'

    Owner                    Branches    Updated
    ------                   --------    -------
    justintoo                2           01-May-12
    rose-compiler            3           27-Apr-12

    $ git forks list --reverse
    --------------------------------------------------------------------------------
    Forks of 'doubleotoo/foo'

    Owner                    Branches    Updated
    ------                   --------    -------
    rose-compiler            3           27-Apr-12
    justintoo                2           01-May-12

    $ git forks show justintoo
    --------------------------------------------------------------------------------
    Owner    : justintoo
    Created  : 01-May-12
    Updated  : 01-May-12
    Branches : 2
      444a867d338cafc0c82d058b458b4fe268fa14d6 master
      14178fe5b204c38650de8ddaf5d9fb80aa834e74 foo


Installation
------------

To install it via Rubygems, you might need to add Gemcutter to your Rubygems sources:

    gem install gemcutter --source http://gemcutter.org

Afterwards simply do:

    gem install git-forks

(Prefix with `sudo` if necessary)

You can retrieve Fork branches matching a regular expression:

    git config --local github.forks.branchpattern <Ruby::Regexp>

(Multiple `branchpattern` regular expressions can be specified. The resulting Regexp will be OR'd together.)

