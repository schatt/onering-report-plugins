Facter.add('site') do
  setcode do
    if File.size?('/etc/onering/static/site')
      site = File.read('/etc/onering/static/site').strip.chomp

    else
      if File.exists?('/proc/cmdline')
        site = (File.read('/proc/cmdline').chomp.split(' ').select{|i| i =~ /^domain=/ }.first rescue nil)
        site = site.split('=', 2).last if site
        site = site.split('.').first if site
      end
    end

    site = nil if ['test', 'hw', 'vm'].include?(site)

    if site
      site
    else
      Facter.value('fqdn').split('.')[-3].downcase rescue nil
    end
  end
end

Facter.add('environment') do
  setcode do
    env = (Facter.value('fqdn').split('.').first.split('-')[-2].downcase rescue nil)

    case env
    when 'dev'
      'development'
    when /(stg|stage)/
      'staging'
    when 'prod'
      'production'
    else
      nil
    end
  end
end

Facter.add('slot') do
  setcode do
    slot = Integer(Facter::Util::Resolution.exec("bmc node_number 2> /dev/null")) rescue nil
    slot = nil if slot == 0
    slot
  end
end


ipmi_ok = (Facter::Util::Resolution.exec("ipmiutil health 2> /dev/null | tail -n1 | grep failed") === nil)

if ipmi_ok
  ipmi_lan = Facter::Util::Resolution.exec("ipmitool lan print 1 2> /dev/null")

  if ipmi_lan
    ipmi_lan_data = {}

    ipmi_lan.lines.each do |line|
      key, value = line.split(/:/, 2)
      value = value.strip.squeeze(' ').chomp

      case key
      when /^IP Address/i
        ipmi_lan_data[:ip] = value

      when /^Subnet Mask/i
        ipmi_lan_data[:netmask] = value

      when /^MAC Address/i
        ipmi_lan_data[:macaddress] = value.upcase

      when /^Default Gateway IP/i
        ipmi_lan_data[:gateway] = value

      when /^SNMP Community String/i
        ipmi_lan_data[:snmp_community] = value

      end
    end

    ipmi_lan_data.each do |key, value|
      Facter.add("ipmi_#{key}") do
        setcode { value }
      end
    end
  end
end
