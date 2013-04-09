# Onering Collector - Base Statistics plugin
#   provides basic system statistics and hardware profile to the Onering API
#

report do
# ------------------------------------------------------------------------------
# filesystem
#
  stats_fs = {}
  current_dev = nil

# logical mounts
  File.open("/etc/mtab").each do |line|
    dev,mount,fstype,flags,dump,pass = line.split(/\s+/)

    stats_fs[dev] = {
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
      next unless stats_fs[dev] and stats_fs[dev].is_a?(Hash)

      stats_fs[dev][:used] = (used.to_i * 1024)
      stats_fs[dev][:available] = (free.to_i * 1024)
      stats_fs[dev][:total] = (stats_fs[dev][:available] + stats_fs[dev][:used])
      stats_fs[dev][:percent_used] = percent.delete('%').to_i
    end
  end


# ------------------------------------------------------------------------------
# memory
#
  stats_mem = {}

  File.open("/proc/meminfo").each do |line|
    case line
    when /^MemTotal:\s+(\d+)/
      stats_mem[:total] = ($1.to_i * 1024)
    when /^SwapTotal:\s+(\d+)/
      stats_mem[:swap] = ($1.to_i * 1024)
    end
  end


# ------------------------------------------------------------------------------
# cpu
#
  stats_cpu = {
    :count => 0,
    :processors => []
  }

  current_cpu = nil

  File.open("/proc/cpuinfo").each do |line|
    case line
    when /processor\s+:\s(.+)/
      current_cpu = $1.to_i
      stats_cpu[:count] += 1
      stats_cpu[:processors][current_cpu] = {
        :number => current_cpu
      }
    when /cpu MHz\s+:\s(.+)/
      stats_cpu[:processors][current_cpu][:speed] = $1.to_f
    end
  end


# ------------------------------------------------------------------------------
# set stat properties
#
  stat :disk, stats_fs.select{|k,v| k =~ /^\/dev\/((h|s|xv|v)d|mapper)/ }.values rescue []
  stat :memory, stats_mem
  stat :cpu, ({
    'count' => stats_cpu[:count].to_i,
    'speed' => stats_cpu[:processors].collect{|i| i[:speed] }.compact.uniq.sort{|a,b| a.to_f <=> b.to_f }.last.to_f
  } rescue nil)
end
