# Onering Collector - HAProxy
#   provides data on HAProxy services
#

report do
  haproxy = Facter.value('haproxy')
  property :@haproxy, haproxy unless haproxy.nil?
end