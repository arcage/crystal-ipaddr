class IPAddr
  class Error < Exception; end

  class InvalidAddressValue < Error
    # :nodoc:
    def initialize(value, version)
      super("#{value} is not a valid #{version} value")
    end
  end

  class InvalidAddressFormat < Error
    # :nodoc:
    def initialize(str, version)
      super("#{str} is not a #{version}")
    end
  end

  class InvalidAddressType < Error
    # :nodoc:
    def initialize(type1, type2)
      super("#{type1} is not a #{type2}")
    end
  end

  class InvalidAddressFamily < Error
    # :nodoc:
    def initialize(address_family)
      super("#{address_family} is not a INET | INET6")
    end
  end

  class InvalidNetworkAddressFormat < Error
    # :nodoc:
    def initialize(str)
      super("#{str} is not a network address")
    end
  end

  class IPVersionMismatch < Error
    # :nodoc:
    def initialize(ip1 : IPAddr, ip2 : IPAddr)
      super("A version of \"#{ip2}\" is different from \"#{ip1}\". ")
    end
  end

  class InvalidPrefixLength < Error
    # :nodoc:
    def initialize(preflen : Int, address_family : Family)
      super("#{preflen} is not a prefix length for #{address_family}. ")
    end
  end
end
