require 'addressable/uri'

module DataObjects

  # A DataObjects URI is of the form scheme://user:password@host:port/path#fragment
  #
  # The elements are all optional except scheme and path:
  # scheme:: The name of a DBMS for which you have a do_\&lt;scheme\&gt; adapter gem installed. If scheme is *jdbc*, the actual DBMS is in the _path_ followed by a colon.
  # user:: The name of the user to authenticate to the database
  # password:: The password to use in authentication
  # host:: The domain name (defaulting to localhost) where the database is available
  # port:: The TCP/IP port number to use for the connection
  # path:: The name or path to the database
  # query:: Parameters for the connection, for example encoding=utf8
  # fragment:: Not currently known to be in use, but available to the adapters
  class URI
    attr_reader :scheme, :subscheme, :user, :password, :host, :port, :path, :query, :fragment

    # Make a DataObjects::URI object by parsing a string. Simply delegates to Addressable::URI::parse.
    def self.parse(uri)
      return uri if uri.kind_of?(self)

      if uri.kind_of?(Addressable::URI)
        scheme = uri.scheme
      else
        if uri[0,4] == 'jdbc'
          scheme    = uri[0,4]
          uri       = Addressable::URI::parse(uri[5, uri.length])
          subscheme = uri.scheme
        else
          uri       = Addressable::URI::parse(uri)
          scheme    = uri.scheme
          subscheme = nil
        end
      end

      self.new(
                :scheme     => scheme,
                :subscheme  => subscheme,
                :user       => uri.user,
                :password   => uri.password,
                :host       => uri.host,
                :port       => uri.port,
                :path       => uri.path,
                :query      => uri.query_values,
                :fragment   => uri.fragment,
                :relative   => !!uri.to_s.index('//') # basic (naive) check for relativity / opaqueness
              )
    end

    def initialize(*args)
      if (component = args.first).kind_of?(Hash)
        @scheme     = component[:scheme]
        @subscheme  = component[:subscheme]
        @user       = component[:user]
        @password   = component[:password]
        @host       = component[:host]
        @port       = component[:port]
        @path       = component[:path]
        @query      = component[:query]
        @fragment   = component[:fragment]
        @relative   = component[:relative]
      elsif args.size > 1
        warn "DataObjects::URI.new with arguments is deprecated, use a Hash of URI components (#{caller.first})"
        @scheme, @user, @password, @host, @port, @path, @query, @fragment = *args
      else
        raise ArgumentError, "argument should be a Hash of URI components, was: #{args.inspect}"
      end
    end

    def opaque?
      !@relative
    end

    def relative?
      @relative
    end

    # Display this URI object as a string
    def to_s
      string = ""
      string << "#{scheme}:"     if scheme
      string << "#{subscheme}:"  if subscheme
      string << '//'             if relative?
      if user
        string << "#{user}"
        string << ":#{password}" if password
        string << "@"
      end
      string << "#{host}"        if host
      string << ":#{port}"       if port
      string << path.to_s
      if query
        string << "?" << query.map do |key, value|
          "#{key}=#{value}"
        end.join("&")
      end
      string << "##{fragment}"   if fragment
      string
    end

    # Compare this URI to another for hashing
    def eql?(other)
      to_s.eql?(other.to_s)
    end

    # Hash this URI
    def hash
      to_s.hash
    end

  end
end
