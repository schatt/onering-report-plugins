report do
  interfaces = {}
  ips = []

  Facter.value('network_interfaces').each do |iface|
    iface = iface.to_sym
    next if [:dummy0, :lo, :sit0].include?(iface)
    interfaces[iface] ||= {}

    mac = (Facter.value("macaddress_#{iface}").upcase rescue nil)
    mtu = (Integer(Facter.value("mtu_#{iface}")) rescue nil)

    interfaces[iface][:name] = iface
    interfaces[iface][:mac] = mac if mac
    interfaces[iface][:mtu] = mtu if mtu

    ips << Facter.value("ipaddress_#{iface}")

    addresses = [{
      :ip       => Facter.value("ipaddress_#{iface}"),
      :netmask  => Facter.value("netmask_#{iface}")
    }.reject{|k,v| v === nil }]

    interfaces[iface][:addresses] = addresses unless addresses.empty? or addresses.reject{|i| i.empty? }.empty?

  # LLDP autodiscovery
    switch = {
      :name         => Facter.value("lldp_switch_#{iface}"),
      :port         => Facter.value("lldp_port_#{iface}"),
      :port_name    => Facter.value("lldp_port_name_#{iface}"),
      :port_mac     => Facter.value("lldp_port_mac_#{iface}"),
      :ip           => Facter.value("lldp_management_ip_#{iface}"),
      :chassis_mac  => Facter.value("lldp_chassis_mac_#{iface}"),
      :vlan         => Facter.value("lldp_vlan_#{iface}"),
      :tagged_vlans => Facter.value("lldp_tagged_vlans_#{iface}")
    }.reject{|k,v| v === nil }


  # Bonding configuration

  # slaves
    master = Facter.value("bonding_master_#{iface}")
    interfaces[iface][:master] = master if master

  # masters
    bond = {
      :arp_ip_target => Facter.value("bonding_arp_ip_target_#{iface}")
    }.reject {|k,v| v === nil }


  # conditionally add applicable subsections
    interfaces[iface][:switch]  = switch unless switch.empty?
    interfaces[iface][:bonding] = bond unless bond.empty?
  end

  property :network, {
    :@ip         => ips,
    :@interfaces => interfaces.values,
    :@sockets    => Facter.value('netstat')
  }
end
