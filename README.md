Design and skeleton thanks to [schacon/git-pulls](https://github.com/schacon/git-pulls) and [b4mboo/git-review](https://github.com/b4mboo/git-review).


git-forks
----------

Get info about a GitHub project's forks.

    $ git forks update
    Retrieving the latest GitHub data...

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

    $ git forks browse justintoo
    > launch web browser to view in GitHub

    $ git forks browse justintoo:test-branch
    > launch web browser to view in GitHub

    $ git forks browse justintoo:c4a8c4aef3814e74f79a1f8a4894618b49ad7486
    > launch web browser to view in GitHub

    $ git forks fetch
    Retrieving the latest GitHub data...
    --------------------------------------------------------------------------------
    Fething Git data from fork 'justintoo/foo'
    From https://github.com/justintoo/foo
     * [new branch]      foo        -> refs/forks/justintoo/foo/foo
     * [new branch]      master     -> refs/forks/justintoo/foo/master
    --------------------------------------------------------------------------------
    Fething Git data from fork 'rose-compiler/foo'
    remote: Counting objects: 12, done.
    remote: Compressing objects: 100% (4/4), done.
    remote: Total 7 (delta 1), reused 7 (delta 1)
    Unpacking objects: 100% (7/7), done.
    From https://github.com/rose-compiler/foo
     * [new branch]      master     -> refs/forks/rose-compiler/master
     * [new branch]      rosecompiler-rc -> refs/forks/rose-compiler/rosecompiler-rc

    $ git forks fetch justintoo
    Retrieving the latest GitHub data...
    --------------------------------------------------------------------------------
    Fething Git data from fork 'justintoo/foo'
    From https://github.com/justintoo/foo
     * [new branch]      foo        -> refs/forks/justintoo/foo
     * [new branch]      master     -> refs/forks/justintoo/master


Configure which forks you are interested in:

    $ git forks config list

    $ git forks config add justintoo
    Added justintoo

    $ git forks config add rose-compiler
    Added rose-compiler

    $ git forks config list
    justintoo
    rose-compiler

    $ git forks config remove rose-compiler
    Removed rose-compiler.

    $ git forks config get rose-compiler


Installation
------------

To install it via Rubygems, you might need to add Gemcutter to your Rubygems sources:

    gem install gemcutter --source http://gemcutter.org

Afterwards simply do:

    gem install git-forks

(Prefix with `sudo` if necessary)
