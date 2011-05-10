toto bongo
====

Minimal blog forked from toto to use for your existing app's. 
This is very useful for SEO optimization


introduction
------------

toto-bongo is a git-powered, minimalist blog engine forked from toto. 
There is no toto client, and there probably will never be, everything goes through git.
From the security stand point, this makes toto-bongo very secure. By
reducing the attack surface( we don't handle any user input) we've made
a blog you can trust. 
Other blogs have administration panels, sessions, cookies etc, that lead
to security vulnerabilities, toto-bongo has non of that.

blog in your app in 10 seconds
------------------

Toto-bongo was designed to be used with a reverse-proxy cache, such as [Varnish](http://varnish-cache.org).
This makes it an ideal candidate for **[heroku](http://heroku.com)**.

This is how to deploy in your existing app:

1. git clone git@github.com:danpal/toto-bongo-blog.git
2. Look at toto-bongo-blog Gemfile, add the following gems to your
   Gemfile.
  
  gem 'toto-bongo'
  gem 'RedCloth'
  gem 'haml'
  
3. Toto-bongo runs on rack, you need to modify your existing config.ru
we provide you with an already existing config.ru, take a look at toto-bongo-blog
config.ru

Then make the following changes
  1. Change :title
  2. Run TotoBongoBlog::Application #change for your application name

how it works
------------

- content is entirely managed through **git**; you get full fledged version control for free.
- articles are stored as _.txt_ files, with embeded metadata (in yaml format).
- articles are processed through a textile converter(RedCloth) by default.
- templating is done through **HAML**.
- toto is built right on top of **Rack**.
- toto was built to take advantage of _HTTP caching_.
- toto was built with heroku in mind.
- comments are handled by [disqus](http://disqus.com)
- individual articles can be accessed through urls such as _/2009/11/21/blogging-with-toto_
- the archives can be accessed by year, month or day, wih the same format as above.
- arbitrary metadata can be included in articles files, and accessed from the templates.
- summaries are generated intelligently by toto, following the `:max` setting you give it.
- you can also define how long your summary is, by adding `~` at the end of it (`:delim`).

toto-blog
-------

### deployment

Toto is built on top of **Rack**, and hence has a **rackup** file: _config.ru_.

#### on your own server

Once you have created the remote git repo, and pushed your changes to it, you can run toto with any Rack compliant web server,
such as **thin**, **mongrel** or **unicorn**.

With thin, you would do something like:

    $ thin start -R config.ru

With unicorn, you can just do:

    $ unicorn

### configuration

You can configure toto, by modifying the _config.ru_ file. For example, if you want to set the blog author to 'John Galt',
you could add `set :author, 'John Galt'` inside the `Toto::Server.new` block. Here are the defaults, to get you started:

    set :author,      ENV['USER']                               # blog author
    set :title,       Dir.pwd.split('/').last                   # site title
    set :url,         'http://example.com'                      # site root URL
    set :prefix,      'blog'                                        # common path prefix for all pages
    set :root,        "index"                                   # page to load on /
    set :date,        lambda {|now| now.strftime("%d/%m/%Y") }  # date format for articles
    set :disqus,      false                                     # disqus id, or false
    set :summary,     :max => 150, :delim => /~\n/              # length of article summary and delimiter
    set :ext,         'txt'                                     # file extension for articles
    set :cache,       28800                                     # cache site for 8 hours

    set :to_html   do |path, page, ctx|                         # returns an html, from a path & context
      ERB.new(File.read("#{path}/#{page}.rhtml")).result(ctx)
    end

    set :error     do |code|                                    # The HTML for your error page
      "<font style='font-size:300%'>toto-bongo, error (#{code})</font>"
    end

### Development

rake gemspec: To generate the gemspec
gem build toto-bongo.gemspec to build

If you are developing use the following enviromental variable to get
some debugging output
export TOTODEBUG=true 



thanks
------

To toto team, as they are the real developers behind toto.


