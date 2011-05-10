require 'yaml'
require 'date'
require 'haml'
require 'rack'
require 'digest'
require 'open-uri'
require 'RedCloth'
require 'builder'
require 'Logger'
$:.unshift File.dirname(__FILE__)

require 'ext/ext'

#
# TotoBongo
#
# TotoBongo Consits of the following
# 
# Module TotoBongo
#   encapsulates the app
#
# Module Template
#   Handles the conversions to html
#
#
module TotoBongo

  #default paths
  Paths = {
    :templates => "templates",
    :pages => "templates/pages",
    :articles => "articles"
  }

  def self.env
    ENV['RACK_ENV'] || 'production'
  end

  def self.env= env
    ENV['RACK_ENV'] = env
  end

  class << self
    attr_accessor :logger
  end
  
  @logger = Logger.new(STDOUT)
  @logger.level = Logger::WARN
  
  #set logger for debug
  if(ENV['TOTODEBUG'])
    @logger.level = Logger::DEBUG
  end
  
  #
  # Handles all templating options
  # Is responsible for:
  # 1. Calling the Haml engine on pages to render them to html
  # 2. Calling the Textile engine on textile text to render them to html
  # 3. Registering All the classes at initialization 
  #
  module Template
    #
    # This will call Haml render
    # Call the config block to make convert the
    # page to html
    #
    #
    def to_html page, config, &blk
      TotoBongo::logger.debug("Called Template::to_html")
      path = ([:layout, :repo].include?(page) ? Paths[:templates] : Paths[:pages])
      result = config[:to_html].call(path, page, binding)
    end

    #
    #Converst a textile text into html
    #
    def textile text
     TotoBongo::logger.debug("Called Template::Textile")
     RedCloth.new(text.to_s.strip).to_html
    end

    #
    # Intercept any method missing 
    #
    def method_missing m, *args, &blk
      TotoBongo::logger.debug("Called method_missing: method = #{method_missin}")
      self.keys.include?(m) ? self[m] : super
    end


    # define the following methods during initialization
    # TotoBongo::Site::Context
    # TotoBongo::Repo 
    # TotoBongo::Archives
    # TotoBongo::Article
    #
    def self.included obj
      TotoBongo::logger.debug("Called Template::include: obj = #{obj}")
      obj.class_eval do
        define_method(obj.to_s.split('::').last.downcase) { self }
      end
    end
 
  end #Template

 
  
  # Site
  # Is responsible for handling the site
  # It has handles the  
  #
  #
  class Site

    def initialize config
      TotoBongo::logger.debug("Called Site::initialize")
      @config = config
    end

    def [] *args
      TotoBongo::logger.debug("Called Site::[]: args = #{args}")
      @config[*args]
    end

    def []= key, value
      TotoBongo::logger.debug("Called Site::[]=: key = #{key} value=#{value}")
      @config.set key, value
    end

    #Called when index is requested
    #
    def index type = :html
      TotoBongo::logger.debug("Called Site::index")
      articles = type == :html ? self.articles.reverse : self.articles
      #know initialize the articles
      {:articles => articles.map do |article|
        Article.new article, @config
      end}.merge archives
    end
    
    
    # 
    # Called in index After initializing the article
    # 
    def archives filter = ""
      TotoBongo::logger.debug("Called Site::archive ")
      entries = ! self.articles.empty??
        self.articles.select do |a|
          filter !~ /^\d{4}/ || File.basename(a) =~ /^#{filter}/
        end.reverse.map do |article|
          Article.new article, @config
        end : []
      return :archives => Archives.new(entries, @config)
    end

    def article route
      TotoBongo::logger.debug("Called Site::article ")
      Article.new("#{Paths[:articles]}/#{route.join('-')}.#{self[:ext]}", @config).load
    end

    # called when the user requests a / 
    # Returns whatever the site index config is
    # default is "index"
    def /
      TotoBongo::logger.debug("Called Site::/ ")
      self[:root]
    end

    #
    # Called by the server after the route and the mime type are 
    # taken from the request, 
    #
    # This is the first function that is called from
    # the server.
    # It should return the html to render
    #
    def go route, env = {}, type = :html
      TotoBongo::logger.debug("Called Site::go ")
      #check if the request includes an specific route
      #else call / to get the index 
      route << self./ if route.empty?

      type, path = type =~ /html|xml|json/ ? type.to_sym : :html, route.join('/')
      context = lambda do |data, page|
        Context.new(data, @config, path, env).render(page, type)
      end

      body, status = if Context.new.respond_to?(:"to_#{type}")

        if route.first =~ /\d{4}/
          case route.size
            when 1..3
              context[archives(route * '-'), :archives]
            when 4
              context[article(route), :article]
            else 
              puts "400"
              http 400
          end #end case


        # Responde to a path, when the request is for example index  
        elsif respond_to?(path)
          #call the path, it will return the HTML of the path
          context[send(path, type), path.to_sym]
        else
          context[{}, path.to_sym]
        end
      else
        http 400
      end #end context new respond

    return body, status

    rescue Errno::ENOENT => e
       TotoBongo::logger.info("Errno:ENOENT: #{e.message} ")
       return :body => http(404).first, :type => :html, :status => 404
    else
      TotoBongo::logger.debug("Status set 200 OK")
      return :body => body || "", :type => type, :status => status || 200
    end



  protected

    #sets the error code 
    def http code
      TotoBongo::logger.debug("http with code #{code}")
      [@config[:error].call(code), code]
    end

    # return a path to an article
    def articles
      TotoBongo::logger.debug("articles")
      self.class.articles self[:ext]
    end

    #
    #Returns the path to an article based on an extension
    #Default ext is .txt
    def self.articles ext
      TotoBongo::logger.debug("self.articles")
      Dir["#{Paths[:articles]}/*.#{ext}"].sort_by {|entry| File.basename(entry) }
    end


    #
    # This class holds all the context to set the scope during rendering
    # The context has access to the config and the article 
    # and defines all the article and archive method
    # 
    class Context
      include Template
      attr_reader :env

      def initialize ctx = {}, config = {}, path = "/", env = {}
        TotoBongo::logger.debug("Initialize context")
        @config, @context, @path, @env = config, ctx, path, env
        #for each article, initialize an article object
        @articles = Site.articles(@config[:ext]).reverse.map do |a|
          Article.new(a, @config)
        end

        ctx.each do |k, v|
          meta_def(k) { ctx.instance_of?(Hash) ? v : ctx.send(k) }
        end
        TotoBongo::logger.debug("End of initialize context")
      end

      def title
        TotoBongo::logger.debug("Context::title")
        @config[:title]
      end
      
      def description
        TotoBongo::logger.debug("Context::desciption")
        @config[:description]
      end
    
      def keywords
        TotoBongo::logger.debug("Context::keywords")
        @config[:keywords]
      end


      def render page, type
        TotoBongo::logger.debug("Context::render")
        content = to_html page, @config
        type == :html ? to_html(:layout, @config, &Proc.new { content }) : send(:"to_#{type}", page)
      end

      def to_xml page
        TotoBongo::logger.debug("Context::to_xml")
        xml = Builder::XmlMarkup.new(:indent => 2)
        instance_eval File.read("#{Paths[:templates]}/#{page}.builder")
      end
      alias :to_atom to_xml

      def method_missing m, *args, &blk
        TotoBongo::logger.debug("Context::missing_method #{m}")
        @context.respond_to?(m) ? @context.send(m, *args, &blk) : super
      end
    
    end #end class contex
  
  end #End site 


  class Archives < Array
    include Template

    def initialize articles, config
      TotoBongo::logger.debug("Archives::initialize")
      self.replace articles
      @config = config
    end

    def [] a
      TotoBongo::logger.debug("Archives::[]: a = #{a}")
      a.is_a?(Range) ? self.class.new(self.slice(a) || [], @config) : super
    end

    def to_html
      TotoBongo::logger.debug("Archives::to_html")
      super(:archives, @config)
    end
    alias :to_s to_html
    alias :archive archives
  end



  class Article < Hash
    include Template

    def initialize obj, config = {}
      TotoBongo::logger.debug("Article::initialize")
      @obj, @config = obj, config
      self.load if obj.is_a? Hash
    end

      
    def load
      TotoBongo::logger.debug("Article::load")
      data = if @obj.is_a? String
        meta, self[:body] = File.read(@obj).split(/\n\n/, 2)

        # use the date from the filename, or else toto won't find the article
        @obj =~ /\/(\d{4}-\d{2}-\d{2})[^\/]*$/
        ($1 ? {:date => $1} : {}).merge(YAML.load(meta))
      elsif @obj.is_a? Hash
        @obj
      end.inject({}) {|h, (k,v)| h.merge(k.to_sym => v) }

      self.taint
      self.update data
      self[:date] = Date.parse(self[:date].gsub('/', '-')) rescue Date.today
      self
    end

    #
    # Called by path when constructing the SEO url
    #
    def [] key
      TotoBongo::logger.debug("Article::key: key = #{key}")

      self.load unless self.tainted?
      super
    end

    def slug
      TotoBongo::logger.debug("Article::slug")
      self[:slug] || self[:title].slugize
    end

    #create a small summary of the body.
    # Defaulsts 150 characters
    def summary length = nil
      TotoBongo::logger.debug("Article::summary")
      config = @config[:summary]
      sum = if self[:body] =~ config[:delim]
        self[:body].split(config[:delim]).first
      else
        self[:body].match(/(.{1,#{length || config[:length] || config[:max]}}.*?)(\n|\Z)/m).to_s
      end
      textile(sum.length == self[:body].length ? sum : sum.strip.sub(/\.\Z/, '&hellip;'))
    end

    def url
      TotoBongo::logger.debug("Article::url")
      "http://#{(@config[:url].sub("http://", '') + self.path).squeeze('/')}"
    end
    alias :permalink url

    def body
      TotoBongo::logger.debug("Article::body")
      textile self[:body].sub(@config[:summary][:delim], '') rescue textile self[:body]
    end
    
    #Path returns a SEO friendly URL path
    # Eg for blog/articles/1900-05-17-the-wonderful-wizard-of-oz.txt
    # it returns /blog/1900/05/17/the-wonderful-wizard-of-oz/
    def path
      TotoBongo::logger.debug("Article::path")
      "/#{@config[:prefix]}#{self[:date].strftime("/%Y/%m/%d/#{slug}/")}".squeeze('/')
    end

    def title()   
      TotoBongo::logger.debug("Article::title")
      self[:title] || "an article"
    end
    def date() 
      TotoBongo::logger.debug("Article::path")
      @config[:date].call(self[:date])        
 
    end
    def author() 
      TotoBongo::logger.debug("Article::path")
      self[:author] || @config[:author]  
    end
    
    def description()
      TotoBongo::logger.debug("Article::path")
      self[:description] || title()  
    end
      
    def keywords()
      TotoBongo::logger.debug("Article::keywords")
      self[:keywords] || title()  
    end


    def to_html() 
      TotoBongo::logger.debug("Article::path")
      self.load; super(:article, @config) 
    end
    alias :to_s to_html
  
  end




  class Config < Hash

    #
    #This is the hash that stores all teh configuation options
    #

    Defaults = {
      :author => ENV['USER'],                               # blog author
      :title => Dir.pwd.split('/').last,                    # blog index title
      :description => "Blog for your existing rails app",   # blog meta description
      :keywords => "blog rails existing",                   # blog meta keywords
      :root => "index",                                     # site index
      :url => "http://127.0.0.1",                           # root URL of the site
      :prefix => "blog",                                        # common path prefix for the blog
      :date => lambda {|now| now.strftime("%d/%m/%Y") },    # date function
      :disqus => false,                                     # disqus name
      :summary => {:max => 150, :delim => /~\n/},           # length of summary and delimiter
      :ext => "txt",                                        # extension for articles
      :cache => 28800,                                      # cache duration (seconds)
      :to_html => lambda {|path, page, ctx|                 # returns an html, from a path & context
        Haml::Engine.new(File.read("#{path}/#{page}.html.haml")).render(ctx)
      },
      :error => lambda {|code|                              # The HTML for your error page
        "<font style='font-size:300%'>toto-bongo error (#{code})</font>"
      }
    }

    
    def initialize obj
    
      self.update Defaults
      self.update obj
    end

    def set key, val = nil, &blk
      if val.is_a? Hash
        self[key].update val
      else
        self[key] = block_given?? blk : val
      end
    end
  end






  # The HTTP server
  class Server
    attr_reader :config, :site
    
    def initialize config = {}, &blk
      @config = config.is_a?(Config) ? config : Config.new(config)
      @config.instance_eval(&blk) if block_given?
      @site = TotoBongo::Site.new(@config)
    end

  
    #
    # This is the entry point of the request
    # On each request, this is the first method that gets
    # called
    #
    def call env
      TotoBongo::logger.debug("***************REQUEST BEGIN*************")
      @request  = Rack::Request.new env
      @response = Rack::Response.new
      return [400, {}, []] unless @request.get?


      #puts "Request path info is: #{@request.path_info}"

      path, mime = @request.path_info.split('.')
      route = (path || '/').split('/').reject {|i| i.empty? }

      response = @site.go(route, env, *(mime ? mime : []))

      @response.body = [response[:body]]
      @response['Content-Length'] = response[:body].length.to_s unless response[:body].empty?
      @response['Content-Type']   = Rack::Mime.mime_type(".#{response[:type]}")

      # Set http cache headers
      @response['Cache-Control'] = if TotoBongo.env == 'production'
        "public, max-age=#{@config[:cache]}"
      else
        "no-cache, must-revalidate"
      end

      @response['ETag'] = %("#{Digest::SHA1.hexdigest(response[:body])}")
      TotoBongo::logger.debug("****************REQUEST END******************")

      @response.status = response[:status]
      @response.finish
    end
  end
end

