report do
# ------------------------------------------------------------------------------
# LVM
#
  vg = {}

# volume groups
  Facter::Util::Resolution.exec("vgdisplay -c 2> /dev/null").to_s.lines.each do |line|
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
  Facter::Util::Resolution.exec("lvdisplay -c 2> /dev/null").to_s.lines.each do |line|
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
  Facter::Util::Resolution.exec("pvdisplay -c 2> /dev/null").to_s.lines.each do |line|
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

  lvm = {}
  lvm = {
    :@groups => vg.values
  } unless vg.values.empty?

  stat 'disk.@lvm', lvm unless lvm.empty?
end