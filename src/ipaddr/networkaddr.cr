class IPAddr
  class NetworkAddr
    # :nodoc:
    MASK_VALUE = {V4 => [BigInt.new(0)], V6 => [BigInt.new(0)]}
    [V4, V6].each do |v|
      BIT_SIZE[v].times do |i|
        mask_value = BigInt.new(0)
        (i + 1).times do |j|
          mask_value += (BigInt.new(1) << (BIT_SIZE[v] - j - 1))
        end
        MASK_VALUE[v] << mask_value
      end
    end

    def self.mask_value(prefix_length : Int, address_family : Family) : BigInt
      raise Error.new if prefix_length < 0
      MASK_VALUE[address_family][prefix_length]
    rescue
      raise InvalidPrefixLength.new(prefix_length, address_family)
    end

    getter begin : IPAddr
    getter end : IPAddr
    getter preflen : Int32

    def_equals_and_hash @begin, @preflen

    def initialize(ip_addr : IPAddr, prefix_length : Int)
      @begin = ip_addr & NetworkAddr.mask_value(prefix_length, ip_addr.family)
      @preflen = prefix_length.to_i32
      @end = @begin | (mask_value ^ IPAddr.max_value(family))
    end

    def initialize(address_string : String, prefix_length : Int)
      initialize(IPAddr.new(address_string), prefix_length)
    end

    def initialize(network_address_string : String)
      substrs = network_address_string.split('/')
      ip_addr, prefix_length = case substrs.size
                               when 1
                                 addr = IPAddr.new(substrs[0])
                                 {addr, addr.bit_size}
                               when 2
                                 addr = IPAddr.new(substrs[0])
                                 prefix_str = substrs[1]
                                 prefix_len = if prefix_str =~ ADDRESS_FORMAT[addr.family]
                                                mask_value = IPAddr.new(prefix_str).value
                                                MASK_VALUE[addr.family].index(mask_value) || raise Error.new
                                              elsif prefix_str =~ /\A\d+\z/
                                                prefix_str.to_i
                                              else
                                                raise Error.new
                                              end
                                 {addr, prefix_len}
                               else
                                 raise Error.new
                               end
      initialize(ip_addr, prefix_length)
    rescue Error
      raise InvalidNetworkAddressFormat.new(network_address_string)
    end


    def ===(other : IPAddr) : Bool
      includes?(other)
    end

    def includes?(ip_addr : IPAddr) : Bool
      ip_addr >= @begin && ip_addr <= @end
    end

    def mask_value : BigInt
      NetworkAddr.mask_value(@preflen, family)
    end

    def mask_string : String
      IPAddr.new(mask_value, family).to_s
    end

    def family : Family
      @begin.family
    end

    def succ : self
      if @preflen == 0
        self
      else
        add_value = BigInt.new(1) << (BIT_SIZE[family] - @preflen)
        new_address = @begin + add_value
        NetworkAddr.new(new_address, @preflen)
      end
    end

    # :nodoc:
    def inspect(io)
      io << "#<IPAddr::NetworkAddr:IPv" << @begin.version << " \"" << @begin.to_ex_str << "/" << @preflen << "\">"
    end

    def to_range : Range(IPAddr, IPAddr)
      @begin..@end
    end

    # :nodoc:
    def to_s(io)
      io << @begin << "/" << @preflen
    end
  end
end
