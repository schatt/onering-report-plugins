# Onering Facts - Xen Properties
#   provides collection of Xen (host and guest) properties
#
require 'json'

# get list of xen guest UUIDs
xen = Facter::Util::Resolution.exec("xm list --long 2> /dev/null | grep uuid")

if xen
  xen_uuid = []

  xen.lines.each do |line|
    xen_uuid << line.strip.chomp.split(/[\s+\)]/).last
  end

  if not xen_uuid.empty?
    Facter.add('xen_guests') do
      setcode { xen_uuid.reject{|i| i =~ /^0{8}/ } }
    end
  end
end

# current xen guest: uuid
if File.exists?("/sys/hypervisor/uuid")
  uuid = (File.read("/sys/hypervisor/uuid").strip.chomp rescue nil)

  if uuid and not uuid =~ /^0{8}/
    Facter.add("xen_uuid") do
      setcode { uuid }
    end
  end
end
