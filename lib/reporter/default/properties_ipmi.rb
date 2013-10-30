# Onering Collector - IPMI plugin
#   provides collection of IPMI data using vendor tools
#

report do
  property :ipmi_ip,         Facter.value('ipmi_ip')
  property :ipmi_netmask,    Facter.value('ipmi_netmask')
  property :ipmi_gateway,    Facter.value('ipmi_gateway')
  property :ipmi_macaddress, Facter.value('ipmi_macaddress')
end