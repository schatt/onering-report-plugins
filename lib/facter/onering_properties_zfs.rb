if Facter::Util::Resolution.which("zpool")
  def sz_to_bytes(sz)
    case sz[-1].chr
    when 'K'
      rv = sz[0..-2].to_f * (1024)
    when 'M'
      rv = sz[0..-2].to_f * (1024 ** 2)
    when 'G'
      rv = sz[0..-2].to_f * (1024 ** 3)
    when 'T'
      rv = sz[0..-2].to_f * (1024 ** 4)
    when 'P'
      rv = sz[0..-2].to_f * (1024 ** 5)
    when 'E'
      rv = sz[0..-2].to_f * (1024 ** 6)
    when 'Z'
      rv = sz[0..-2].to_f * (1024 ** 7)
    when 'Y'
      rv = sz[0..-2].to_f * (1024 ** 8)
    else
      rv = sz[0..-2].to_f
    end

    rv.to_i
  end

  zfs = {
    :filesystems => [],
    :pools       => [],
    :snapshots   => []
  }


# =============================================================================
# POOLS
  Facter::Util::Resolution.exec("zpool list -H").to_s.lines.each do |line|
    pool, size, allocated, free, used_perc, dedup, health, altroot = line.strip.split(/\s+/)
    zfs_pool = {
      :name      => pool,
      :status    => health.downcase,
      :size      => {
        :total        => sz_to_bytes(size),
        :allocated    => sz_to_bytes(allocated),
        :free         => sz_to_bytes(free),
        :used         => (sz_to_bytes(size) - sz_to_bytes(free)),
        :percent_used => used_perc.delete('%').to_f
      },
      :deduplication_factor => dedup.delete('x').to_f,
      :virtual_devices => {}
    }

    zfs_pool[:mountpoint] = altroot if altroot != '-'
    vdevs = {}
    current_vdev = nil

  # get vdevs/devices
    Facter::Util::Resolution.exec("zpool status -v #{pool}").to_s.lines.each do |line|
      if line =~ /^\s*([a-z]+):\s+(.*)$/
        case $1
        when 'scan'
        # scrub output
          if $2 =~ /scrub repaired ([0-9]+) in ((?:[0-9]+d)?(?:[0-9]+h)?(?:[0-9]+m)) with ([0-9]+) errors on (.*)$/
            zfs_pool[:scrub] ||= {}
            zfs_pool[:scrub][:repaired]     = $1.to_i
            zfs_pool[:scrub][:errors]       = $3.to_i
            zfs_pool[:scrub][:completed_at] = DateTime.parse($4).strftime("%Y-%m-%d %H:%M:%S %z")
          end
        end

    # vdev line
      elsif line =~ /^\t  ([a-z0-9]+)(?:-([0-9]+))\s+([A-Z]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s*$/
        current_vdev = "#{$1}-#{$2}"
        vdevs[current_vdev] = {
          :name    => "#{$1}-#{$2}",
          :type    => $1.to_sym,
          :number  => $2.to_i,
          :status  => $3.downcase,
          :errors  => {
            :read     => $4.to_i,
            :write    => $5.to_i,
            :checksum => $6.to_i
          },
          :devices => []
        }

    # device line
      elsif line =~ /^\t    ([a-zA-Z0-9\-\_]+)\s+([A-Z]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s*$/
        if File.symlink?("/dev/disk/by-id/#{$1}")
          dev = File.expand_path(File.readlink("/dev/disk/by-id/#{$1}"), "/dev/disk/by-id")
        elsif File.exists?("/dev/#{$1}")
          dev = "/dev/#{$1}"
        end

        vdevs[current_vdev][:devices] << {
          :name    => $1,
          :device  => dev,
          :errors  => {
            :read     => $2.to_i,
            :write    => $3.to_i,
            :checksum => $4.to_i
          }
        }
      end
    end

    vdevs.each do |name, devs|
      zfs_pool[:virtual_devices][name.split('-').first.to_sym] ||= []
      zfs_pool[:virtual_devices][name.split('-').first.to_sym] << devs
    end

    zfs[:pools] << zfs_pool
  end




# =============================================================================
# FILESYSTEMS
  Facter::Util::Resolution.exec("zfs list -H").to_s.lines.each do |line|
    filesystem, used, available, referenced, mountpoint = line.strip.split(/\s+/)

    zfs_filesystem = {
      :name       => filesystem,
      :mountpoint => mountpoint,
      :properties => {},
      :snapshots  => [],
      :size      => {
        :used         => sz_to_bytes(used),
        :free         => sz_to_bytes(available)
      }
    }

  # get properties
    Facter::Util::Resolution.exec("zfs get all -H #{filesystem}").to_s.lines.each do |line|
      fs, property, value, source = line.strip.split(/\t/)

      value = case value
      when 'off'                             then false
      when 'on'                              then true
      when 'none'                            then nil
      when /^[0-9]+(?:\.[0-9]+)?[KMGTPEZY]$/ then sz_to_bytes(value)
      when /^[0-9]+$/                        then value.to_i
      when /^[0-9]+\.[0-9]+$/                then value.to_f
      when /^[0-9]+\.[0-9]+x$/               then value.delete('x').to_f
      else value
      end

      zfs_filesystem[:properties][property.to_sym] = value
    end

    zfs[:filesystems] << zfs_filesystem
  end


# =============================================================================
# SNAPSHOTS
  Facter::Util::Resolution.exec("zfs list -H -t snapshot").to_s.lines.each do |line|
    name, used, available, referenced, mountpoint = line.strip.split(/\s+/)
    mountpoint = nil if mountpoint == '-'

    zfs[:snapshots] << {
      :name       => name,
      :used       => sz_to_bytes(used),
      :available  => sz_to_bytes(available),
      :referenced => sz_to_bytes(referenced),
      :mountpoint => mountpoint
    }
  end


  Facter.add("zfs") do
    setcode{ zfs }
  end
end
