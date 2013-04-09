# Onering Collector - Network Statistics plugin
#   provides network details to the Onering API
#

report do
  stat :network, {
    :sockets => Facter.value('netstat')
  }
end
