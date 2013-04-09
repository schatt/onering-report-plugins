# Onering Collector - Xen Properties plugin
#   provides collection of Xen metadata
#
report do
  xen_guests     = Facter.value('xen_guests')
  xen_guest_uuid = Facter.value('xen_uuid')
  xen = {}

# xen host
  xen[:@guests] = xen_guests  if xen_guests

# xen guest
  xen[:uuid] = xen_guest_uuid if xen_guest_uuid

  property :xen, xen
end
