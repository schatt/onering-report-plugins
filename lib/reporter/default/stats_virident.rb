# Onering Collector - Virident device information
#   provides data on Virident flash mass storage devices
#

report do
  virident = Facter.value('virident')
  stat :@virident, virident unless virident.nil?
end