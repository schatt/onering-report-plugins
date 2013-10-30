report do
# ------------------------------------------------------------------------------
# mounts
#
  mounts = {}
  current_dev = nil

  uuids = Hash[Dir["/dev/disk/by-uuid/*"].collect{|i|
    [File.expand_path(File.readlink(i), File.dirname(i)), File.basename(i)]
  }]

  File.read("/etc/mtab").lines.each do |line|
    dev,mount,fstype,flags,dump,pass = line.split(/\s+/)

    mounts[dev] = {
      :mount      => mount,
      :device     => dev,
      :filesystem => fstype,
      :flags      => flags.split(/\s*,\s*/),
      :uuid       => uuids[dev]
    }.compact
  end

# logical space utilization
  Facter::Util::Resolution.exec("df 2> /dev/null").to_s.lines.each do |line|
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

  stat 'disk.@mounts', (Hash[mounts.select{|k,v| k =~ /^\/dev\/((h|s|xv|v)d|mapper|vgc)/ }].values rescue nil)
end