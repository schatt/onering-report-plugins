# Onering Collector - Disk Statistics plugin
#   provides data on disks, mounts, and RAID configuration
#

report do
# ------------------------------------------------------------------------------
# mounts
#
  mounts = {}
  current_dev = nil

  File.open("/etc/mtab").each do |line|
    dev,mount,fstype,flags,dump,pass = line.split(/\s+/)

    mounts[dev] = {
      :mount      => mount,
      :device     => dev,
      :filesystem => fstype,
      :flags      => flags.split(/\s*,\s*/)
    }
  end

# logical space utilization
  IO.popen("df").lines.each do |line|
    next if line =~ /^Filesystem/
    parts = line.split(/\s+/)

    if parts.length == 1
      current_dev = parts.first
      next

    else
      dev,kblk,used,free,percent,mount = parts
      dev = current_dev if dev.empty?
      next unless mounts[dev] and mounts[dev].is_a?(Hash)

      mounts[dev][:used] = (used.to_i * 1024)
      mounts[dev][:available] = (free.to_i * 1024)
      mounts[dev][:total] = (mounts[dev][:available] + mounts[dev][:used])
      mounts[dev][:percent_used] = percent.delete('%').to_i
    end
  end


# ------------------------------------------------------------------------------
# LVM
#
  vg = {}

# volume groups
  IO.popen("vgdisplay -c").lines.each do |line|
    line = line.strip.chomp.split(':')

    vg[line[0]] = {
      :name    => line[0],
      :uuid    => line[16],
      :size    => (line[11].to_i*1024),
      :extents => {
        :size      => (line[12].to_i * 1024),
        :total     => line[13].to_i,
        :allocated => line[14].to_i,
        :free      => line[15].to_i
      },
      :volumes => [],
      :disks => []
    }
  end

# logical volumes
  IO.popen("lvdisplay -c").lines.each do |line|
    line = line.strip.chomp.split(':')

    unless vg[line[1]].nil?
      vg[line[1]][:volumes] << {
        :name    => line[0],
        :sectors => line[6].to_i,
        :extents => line[7].to_i,
        :size    => (vg[line[1]][:extents][:size] * line[7].to_i)
      }
    end
  end


# physical volumes
  IO.popen("pvdisplay -c").lines.each do |line|
    line = line.strip.chomp.split(':')

    unless vg[line[1]].nil?
      vg[line[1]][:disks] << {
        :name    => line[0],
        :uuid    => line[11],
        :size    => (line[8].to_i * (line[7].to_i * 1024)),  # See Note 1 below
        :extents => {
          :size      => (line[7].to_i * 1024),
          :total     => line[8].to_i,
          :allocated => line[10].to_i,
          :free      => line[9].to_i
        }
      }

    # the output of certain versions of pvdisplay -c reports a blatantly incorrect
    # physical volume total size.  the workaround is to calculate the actual total size
    # via (total extents * extent size)
    #
    # this may or may not be GPT related
    #
    end
  end


  stat :disk, {
    :mounts => (Hash[mounts.select{|k,v| k =~ /^\/dev\/((h|s|xv|v)d|mapper|vgc)/ }].values rescue nil),
    :lvm    => {
      :groups => vg.values
    }
  }
end