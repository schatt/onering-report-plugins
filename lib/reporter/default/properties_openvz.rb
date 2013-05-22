# Onering Collector - OpenVZ Properties plugin
#   provides collection of OpenVZ metadata
#
report do
  vz_containers  = Facter.value('openvz_containers')
  vz = {}

# OpenVZ host
  vz[:@guests] = vz_containers if vz_containers

  property :openvz, vz unless vz.empty?
end
