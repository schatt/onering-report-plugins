# Onering Collector - Physical Properties plugin
#   provides collection of hardware location data using vendor tools
#

report do
  property :site,            Facter.value('site')
  property :environment,     Facter.value('environment')
  property :slot,            Facter.value('slot')
  property :virtual,         Facter.value('is_virtual')
  property :ipmi_ip,         Facter.value('ipmi_ip')
  property :ipmi_netmask,    Facter.value('ipmi_netmask')
  property :ipmi_gateway,    Facter.value('ipmi_gateway')
  property :ipmi_macaddress, Facter.value('ipmi_macaddress')
end
