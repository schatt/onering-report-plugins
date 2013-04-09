# Onering Collector - Service List
#   provides list of certain services that are running on a machine
#
report do
  property :@services, Facter.value('services')
end
