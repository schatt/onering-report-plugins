# Onering Collector - ZFS volume manager information
#   provides data on ZFS pools, filesystems, and snapshots
#

report do
  zfs = Facter.value('zfs')
  stat :@zfs, zfs unless zfs.nil?
end