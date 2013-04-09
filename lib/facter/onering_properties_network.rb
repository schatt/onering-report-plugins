
def _format(key, value)
  rv = []
  value = nil if value =~ /Not received/i

  begin
    case key
    when :autoneg
      v0, v1 = value.split('/')
      rv << [:autoneg_supported, (v0 == 'supported')]
      rv << [:autoneg_enabled, (v1 == 'enabled')]

    when :mgmt_ip
      rv << [:management_ip, value]

    when :mau_oper_type
      rv << [:mau_type, value]

    when :port_id
      value = value.split(' ')
      value = value.select{|i| i =~ /..:..:..:..:..:../ }.first

      rv << [:port_mac, value.upcase]

    when :chassis_id
      value = value.split(' ')
      value = value.select{|i| i =~ /..:..:..:..:..:../ }.first

      rv << [:chassis_mac, value.upcase]

    when :port_descr
      port = value.split(/[^0-9]([0-9])/, 2)
      port.shift
      port = port.join('')

      rv << [:port_name, value]
      rv << [:port, port]

    when :mfs
      rv << [:mfs, (value.split(' ').first.to_i rescue nil)]

    when :sys_name

      rv << [:switch, value]

    when :lldp_med_device_type,
         :lldp_med_capabilities,
         :caps,
         :sys_descr
      return []

    else
      rv << [key, value]
    end
  rescue
    nil
  end

  return rv
end


# Typefix for interfaces fact
Facter.add('network_interfaces') do
  setcode do
    Facter.value("interfaces").split(',')
  end
end

default_if = Facter::Util::Resolution.exec('route -n | grep "^0.0.0.0" | tr -s " " | cut -d " " -f8')

Facter.add('default_gateway') do
  setcode do
    Facter::Util::Resolution.exec('route -n | grep "UG" | tr -s " " | cut -d" " -f2')
  end
end

if default_if
  begin
    default_if.strip!
    default_if.chomp!

    Facter.add('default_interface') do
      setcode { default_if }
    end

    Facter.add('default_macaddress') do
      setcode { Facter.value("macaddress_#{default_if}") }
    end
  rescue
    nil
  end
end

# LLDP
begin
  current_iface = nil
  network_lldp = {}

  output = Facter::Util::Resolution.exec('lldpctl')

  if output
    output.gsub(/^\s+/,'').lines do |line|
      key, value = line.strip.chomp.squeeze(' ').split(/:\s+/, 2)

      if key and value
        key.gsub!(/ID$/, '_id')
        key.gsub!(/[\-\s]+/, '_')
        key.gsub!(/([a-z])([A-Z])/, '\1_\2')
        key = key.downcase.strip.to_sym
        value.strip!
        kvs = _format(key,value)

        kvs.each do |k, v|
          next unless k and v

          if k == :interface
            current_iface = v.split(',').first.to_sym
          else
            network_lldp[current_iface] = {} unless network_lldp[current_iface]
            network_lldp[current_iface][k] = v
          end
        end
      end
    end
  end

  network_lldp.each do |iface, lldp|
    lldp.each do |key, value|
      Facter.add("lldp_#{key}_#{iface}") do
        setcode { value }
      end
    end
  end


# Bonding Configuration
  if Facter.value("osfamily") == "RedHat"
    interfaces = {}

    Facter.value('network_interfaces').each do |iface|
      if File.exists?("/etc/sysconfig/network-scripts/ifcfg-#{iface}")
        sysconfig = Hash[File.read("/etc/sysconfig/network-scripts/ifcfg-#{iface}").lines.collect {|line|
          key, value = line.split('=', 2)
          next unless key and value
          [key.downcase.to_sym, value.strip.chomp]
        }]


        if sysconfig[:master] and (sysconfig[:slave] == 'yes')
          Facter.add("bonding_master_#{iface}") do
            setcode { sysconfig[:master] }
          end
        elsif not (sysconfig[:slave] == 'yes')
          if sysconfig[:bonding_opts]
            opts = Hash[sysconfig[:bonding_opts].gsub(/(^\"|\"$)/,'').split(/\s+/).collect{ |pair|
              pair.split('=')
            }]

            opts.each do |key, value|
              Facter.add("bonding_#{key}_#{iface}") do
                setcode { value }
              end
            end
          end
        end
      end
    end
  end

rescue Exception => e
  STDERR.puts "#{e.name}: #{e.message}"
end