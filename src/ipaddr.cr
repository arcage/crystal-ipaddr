require "big_int"
require "socket"

lib LibC
  INET_ADDRSTRLEN  = 16
  INET6_ADDRSTRLEN = 46
  fun htonl(hostshort : UInt32T) : UInt32T
  fun ntohl(netshort : UInt32T) : UInt32T
end

require "./ipaddr/*"

class IPAddr
  include Comparable(self)

  alias Family = Socket::Family

  # :nodoc:
  V4 = Family::INET
  # :nodoc:
  V6 = Family::INET6

  # :nodoc:
  ADDRESS_FORMAT = {
    V4 => /\A(25[0-5]|2[0-4]\d|([01]?\d)?\d)(\.(25[0-5]|2[0-4]\d|([01]?\d)?\d)){3}\z/,
    V6 => /\A((([0-9a-f]{1,4}:){7}([0-9a-f]{1,4}|:))|(([0-9a-f]{1,4}:){6}(:[0-9a-f]{1,4}|((25[0-5]|2[0-4]\d|([01]?\d)?\d)(\.(25[0-5]|2[0-4]\d|([01]?\d)?\d)){3})|:))|(([0-9a-f]{1,4}:){5}(((:[0-9a-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|([01]?\d)?\d)(\.(25[0-5]|2[0-4]\d|([01]?\d)?\d)){3})|:))|(([0-9a-f]{1,4}:){4}(((:[0-9a-f]{1,4}){1,3})|((:[0-9a-f]{1,4})?:((25[0-5]|2[0-4]\d|([01]?\d)?\d)(\.(25[0-5]|2[0-4]\d|([01]?\d)?\d)){3}))|:))|(([0-9a-f]{1,4}:){3}(((:[0-9a-f]{1,4}){1,4})|((:[0-9a-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|([01]?\d)?\d)(\.(25[0-5]|2[0-4]\d|([01]?\d)?\d)){3}))|:))|(([0-9a-f]{1,4}:){2}(((:[0-9a-f]{1,4}){1,5})|((:[0-9a-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|([01]?\d)?\d)(\.(25[0-5]|2[0-4]\d|([01]?\d)?\d)){3}))|:))|(([0-9a-f]{1,4}:){1}(((:[0-9a-f]{1,4}){1,6})|((:[0-9a-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|([01]?\d)?\d)(\.(25[0-5]|2[0-4]\d|([01]?\d)?\d)){3}))|:))|(:(((:[0-9a-f]{1,4}){1,7})|((:[0-9a-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|([01]?\d)?\d)(\.(25[0-5]|2[0-4]\d|([01]?\d)?\d)){3}))|:)))\z/
  }

  # :nodoc:
  IPV4_COMPAT_FORMAT = /\A::(25[0-5]|2[0-4]\d|([01]?\d)?\d)(\.(25[0-5]|2[0-4]\d|([01]?\d)?\d)){3}\z/
  # :nodoc:
  IPV4_MAPPED_FORMAT = /\A::ffff:(25[0-5]|2[0-4]\d|([01]?\d)?\d)(\.(25[0-5]|2[0-4]\d|([01]?\d)?\d)){3}\z/

  # :nodoc:
  VALUE_RANGE = {
    V4 => BigInt.new(0)..BigInt.new("4294967295"),
    V6 => BigInt.new(0)..BigInt.new("340282366920938463463374607431768211455"),
  }

  # :nodoc:
  BIT_SIZE = {V4 => 32, V6 => 128}

  def self.valid_value!(internal_value : Int, family : Family) : BigInt
    value = internal_value.to_big_i
    raise InvalidAddressValue.new(internal_value, family) unless VALUE_RANGE[family] === internal_value
    value
  end

  def self.valid_address_family!(address_family) : Family
    if address_family == V4 || address_family == V6
      address_family
    else
      raise InvalidAddressFamily.new(address_family)
    end
  end

  def self.infer_address_family(internal_value : Int) : Family
    if internal_value < 0 || internal_value > VALUE_RANGE[V6].end
      raise InvalidAddressValue.new(internal_value, "INET | INET6")
    elsif internal_value > VALUE_RANGE[V4].end
      V6
    else
      V4
    end
  end

  # Returns maximum internal value for each IP version.
  def self.max_value(address_family : Family) : BigInt
    VALUE_RANGE[valid_address_family!(address_family)].end
  end

  # Returns bit size of address for each IP version.
  def self.bit_size(address_family : Family) : Int32
    BIT_SIZE[valid_address_family!(address_family)]
  end

  def self.infer_address_family(address_string : String) : Family
    case address_string.downcase
    when ADDRESS_FORMAT[V4]
      V4
    when ADDRESS_FORMAT[V6]
      V6
    else
      raise InvalidAddressFormat.new(address_string, "INET | INET6")
    end
  end

  def self.htop(internal_value : Int, address_family : Family) : String
    family = valid_address_family!(address_family)
    value = valid_value!(internal_value, family)
    case family
    when V4
      in_addr = uninitialized LibC::InAddr
      in_addr.s_addr = LibC.htonl(value.to_u32)
      in_addr_p = pointerof(in_addr).as(Void*)
      String.new(LibC::INET_ADDRSTRLEN) do |buf|
        addr_len = LibC.inet_ntop(family.value, in_addr_p, buf, LibC::INET_ADDRSTRLEN).null? ? 0 : LibC.strlen(buf)
        {addr_len, addr_len}
      end
    when V6
      in_addr6 = uninitialized LibC::In6Addr
      (0..3).each do |i|
        in_addr6.__u6_addr.__u6_addr32.as(StaticArray(UInt32, 4))[i] = LibC.htonl(((value >> ((3 - i) * 32)) & 0xffffffff).to_u32)
      end
      in_addr6_p = pointerof(in_addr6).as(Void*)
      String.new(LibC::INET6_ADDRSTRLEN) do |buf6|
        addr6_len = LibC.inet_ntop(family.value, in_addr6_p, buf6, LibC::INET6_ADDRSTRLEN).null? ? 0 : LibC.strlen(buf6)
        {addr6_len, addr6_len}
      end
    else
      raise InvalidAddressFamily.new(family)
    end
  end

  def self.ptoh(address_string : String, address_family : Family) : BigInt
    family = valid_address_family!(address_family)
    case family
    when V4
      in_addr = uninitialized LibC::InAddr
      in_addr_p = pointerof(in_addr).as(Void*)
      unless LibC.inet_pton(family.value, address_string.downcase, in_addr_p) == 1
        raise InvalidAddressFormat.new(address_string, family)
      end
      LibC.ntohl(in_addr.s_addr).to_big_i
    when V6
      in_addr6 = uninitialized LibC::In6Addr
      in_addr6_p = pointerof(in_addr6).as(Void*)
      unless LibC.inet_pton(family.value, address_string.downcase, in_addr6_p) == 1
        raise InvalidAddressFormat.new(address_string, family)
      end
      value = BigInt.new(0)
      u32_list = in_addr6.__u6_addr.__u6_addr32.as(StaticArray(UInt32, 4)).map { |u32| LibC.ntohl(u32) }
      u32_list.each_index do |i|
        value += (u32_list[i].to_big_i << ((3 - i) * 32))
      end
      value
    else
      raise InvalidAddressFamily.new(family)
    end
  end

  # Returns internal integer value.
  getter value : BigInt

  # Returns
  getter family : Family

  @address : String

  def_equals_and_hash @value, @family

  def initialize(internal_value : Int, address_family : Family? = nil)
    @family = address_family || IPAddr.infer_address_family(internal_value)
    @value = IPAddr.valid_value!(internal_value, @family)
    @address = IPAddr.htop(@value, @family)
  end

  def initialize(address_string : String)
    address_family = IPAddr.infer_address_family(address_string)
    integer = IPAddr.ptoh(address_string, address_family)
    initialize(integer, address_family)
  end

  def <=>(other : self) : Int32
    @value <=> other.value
  end

  def +(integer : Int) : self
    new_value = (@value + IPAddr.valid_value!(integer, @family)) % (IPAddr.max_value(@family) + 1)
    IPAddr.new(new_value, @family)
  end

  def -(integer : Int) : self
    new_value = (@value + IPAddr.max_value(@family) + 1 - IPAddr.valid_value!(integer, @family)) % (IPAddr.max_value(@family) + 1)
    IPAddr.new(new_value, @family)
  end

  def &(integer : Int) : self
    new_value = @value & IPAddr.valid_value!(integer, @family)
    IPAddr.new(new_value, @family)
  end

  def &(other : self) : self
    self & same_version!(other).value
  end

  def |(integer : Int) : self
    new_value = @value | IPAddr.valid_value!(integer, @family)
    IPAddr.new(new_value, @family)
  end

  def |(other : self) : self
    self | same_version!(other).value
  end

  def ~ : self
    new_value = @value ^ IPAddr.max_value(@family)
    IPAddr.new(new_value, @family)
  end

  def ipv4? : Bool
    @family == V4
  end

  def ipv6? : Bool
    @family == V6
  end

  def succ : self
    self + 1
  end

  # Returns IP version integer(`4` or `6`)
  def version : Int32
    @family == V4 ? 4 : 6
  end

  # :nodoc:
  def inspect(io)
    io << "#<IPAddr:IPv" << version << " \"" << to_ex_str << "\">"
  end

  # :nodoc:
  def to_ex_str : String
    if ipv4?
      @address
    else
      (0..7).map { |i|
        ((@value >> (16 * (7 - i))) & 0xffff).to_s(16).rjust(4, '0')
      }.join(':')
    end
  end

  # :nodoc:
  def to_s(io)
    io << @address
  end

  # Returns `true` when `self` and `other` have same version.
  def same_version?(other : self) : Bool
    @family == other.family
  end

  # Returns `other` when `self` and `other` have same version, or raise `IPVersionMismatch`
  def same_version!(other : self) : self
    if same_version?(other)
      other
    else
      raise IPVersionMismatch.new(self, other)
    end
  end

  def to_ipv4_compat : self
    raise InvalidAddressType.new(self, "IPv4 address") unless ipv4?
    IPAddr.new("::" + @address)
  end

  def to_ipv4_mapped : self
    raise InvalidAddressType.new(self, "IPv4 address") unless ipv4?
    IPAddr.new("::ffff:" + @address)
  end

  def ipv4_compat? : Bool
    !(@address =~ IPV4_COMPAT_FORMAT).nil?
  end

  def ipv4_mapped? : Bool
    !(@address =~ IPV4_MAPPED_FORMAT).nil?
  end

  def native_ipv4 : self
    raise InvalidAddressType.new(self, "IPv4 compatible or mapped address") unless ipv4_compat? || ipv4_mapped?
    IPAddr.new(@value & 0xffffffff, V4)
  end

  def bit_size : Int32
    IPAddr.bit_size(@family)
  end

  def network_address(prefix_length : Int) : NetworkAddr
    NetworkAddr.new(self, prefix_length)
  end
end
