# Onering Collector - Physical Properties plugin
#   provides collection of hardware location data using vendor tools
#

report do
  property :site,            Facter.value('site')
  property :environment,     Facter.value('environment')
  property :slot,            Facter.value('slot')
  property :virtual,         (Facter.value('is_virtual').to_s == 'true' ? true : false)
end
