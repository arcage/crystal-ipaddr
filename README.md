# IPAddr

IP address handling library for [Crystal language](https://crystal-lang.org).

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  ipaddr:
    github: arcage/crystal-ipaddr
```

## Usage

```crystal
require "ipaddr"
```

### IP address object

```crystal
ipv4 = IPAddr.new("169.254.10.1")
# => #<IPAddr:IPv4 "169.254.10.1">
ipv4.to_s
# => "169.254.10.1"

ipv6 = IPAddr.new("2001:db8::deca:face")
# => #<IPAddr:IPv6 "2001:0db8:0000:0000:0000:0000:deca:face">
ipv6.to_s
# => "2001:db8::deca:face"
```

### IPv4 compatible/mapped IPv6 address

```crystal
v4compat = ipv4.to_ipv4_compat
# => #<IPAddr:IPv6 "0000:0000:0000:0000:0000:0000:a9fe:0a01">

v4mapped = ipv4.to_ipv4_mapped
# => #<IPAddr:IPv6 "0000:0000:0000:0000:0000:ffff:a9fe:0a01">

v4compat.native_ipv4
# => #<IPAddr:IPv4 "169.254.10.1">

v4mapped.native_ipv4
# => #<IPAddr:IPv4 "169.254.10.1">
```

### Network address

```crystal
nw  = IPAddr::NetworkAddr.new(ipv4, 16)
# => #<IPAddr::NetworkAddr:IPv4 "169.254.0.0/16">

nw2 = IPAddr::NetworkAddr.new("2001:db8::beaf:cafe", 120)
# => #<IPAddr::NetworkAddr:IPv6 "2001:0db8:0000:0000:0000:0000:beaf:ca00/120">

nw3 = IPAddr::NetworkAddr.new("192.168.20.2/255.255.255.0")
# => #<IPAddr::NetworkAddr:IPv4 "192.168.20.0/24">

nw4 = IPAddr::NetworkAddr.new("2001:db8::beaf:cafe/120")
# => #<IPAddr::NetworkAddr:IPv6 "2001:0db8:0000:0000:0000:0000:beaf:ca00/120">

nw5 = ipv4.network_address(16)
# => #<IPAddr::NetworkAddr:IPv4 "169.254.0.0/16">

nw.begin
# => #<IPAddr:IPv4 "169.254.0.0">

nw.end
# => #<IPAddr:IPv4 "169.254.255.255">

nw.includes?(ipv4)
# => true

```
## Contributing

1. Fork it ( https://github.com/arcage/ipaddr/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [arcage](https://github.com/arcage) ʕ·ᴥ·ʔAKJ - creator, maintainer
