# Onering Facts - OpenVZ Properties
#   provides collection of OpenVZ (host and guest) properties
#
require 'json'

# get list of OpenVZ container hostnames from the host
vzlist = Facter::Util::Resolution.exec("vzlist -o hostname | tail -n+2 2> /dev/null")

if vzlist
  if not vzlist.empty?
    Facter.add('openvz_containers') do
      setcode do
        vzlist.split("\n").collect{|i| i.strip.chomp }.reject{|i| i.empty? }
      end
    end
  end
end
