# mite.cmd

A simple command line interface for basic mite tasks.

* `mite.` is an ingeniously sleek time tracking tool: http://mite.yo.lk
* `mite.cmd` is a command line interface for it: http://github.com/Overbryd/mite.cmd
  It provides a system wide command called `mite`.

### About this branch

Lots of changes to the interface for a more streamlined experience by @ffrank, based on the excellent work by @koppen.

I broke all the tests. The time budget didn't quite allow for TDD. Heart is bleading, but here we are.

### Installation instructions:

    $ git clone https://github.com/ffrank/mite.cmd.git

    $ bundle install

### After installation instructions:

You'll need to configure the client prior using it.
To do this, you can just hammer into your console:

    $ mite configure "Your Account Name" "Your API Key"

e.g.

    $ mite configure ffrank ab56cd1234

It will then generate a yml file in ~/.mite.yml with your account information.

The configure command also tries to install the bash auto completion hook into the following files: `~/.bash_completion`, `~/.bash_profile`, `~/.bash_login`, `~/.bashrc`.

If your system doesn't support one of the files above, install the hook by yourself.
In order to work as expected it needs bash to be configured for auto completion.
This is actually quite easy, just append this line to your bash config file.

  complete -C "mite auto-complete" mite

You could use this command as an example (replace .bash_login with your bash configuration file):

    $ echo "complete -C \"mite auto-complete\" mite" >> ~/.bash_login

For a list of other configurables, see

    $ mite help

or just edit `~/.mite.yml`.

### Create new time entries with ease:

    $ mite add <time> "project name" "service name" note
  
#### Examples:

    $ mite add 0:15 HugEveryone

The time entry created by this command, is made for the project HugEveryone and is set to 15 minutes. No tracker will be started.
  
    $ mite add 1+ HugEveryone Love

Start a time entry for the project HugEveryone with the service Love and set it to 1 hour. The tracker will be started, because of the `start time` argument was suffixed with a `+`.

### Auto-completion:

This is very nifty. (But maybe you should read the After Installation Instructions before.)
The client was designed to save keystrokes, so I've baked in a very handy auto-completion feature.

Try this:

    $ mite [tab]

It will try to auto-complete the available commands. 

    $ mite add [tab]

Now it offers up some common times.
    
    $ mite add 0:30 [tab]

It will try to auto-complete your projects.
    
    $ mite add 0:30 Project1 "System Administration" [tab]

#### Amazingly fast auto-completion:

The auto-completion feature creates a cache in ~/.mite.cache, if you want to rebuild this cache just hit:
  
    $ mite rebuild-cache

#### Note: The first run without the cache might be a bit slow.

### Controlling timers:

    $ mite start

This little cutey will start today's last time entry, if there is one.

    $ mite stop

This will just stop the current timer. (If you like you can use `mite pause` or `mite lunch` too)

### Simple reports:

    $ mite report today

This will generate a report of today's activity, summarizing your earnings at the bottom.

    $ mite report yesterday

This will generate a report of yesterday's activity, summarizing your earnings and the total time at the bottom.
Also works using `this_week`, `last_week`, `this_month`, `last_month` as argument.

### More simple stuff:

    $ mite

If there is a running timer, it will output it. Otherwise you should better not listen to it.

    $ mite +

Just create a new time entry and start tracking it.

    $ mite open

Opens your mite account in a new browser window (Max OSX only) or prints the url to your account.
