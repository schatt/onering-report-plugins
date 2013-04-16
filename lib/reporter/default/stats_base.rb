# Onering Collector - Base Statistics plugin
#   provides basic system statistics and hardware profile to the Onering API
#

report do
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
  stat :memory, stats_mem
  stat :cpu, ({
    'count'    => Facter.value('processorcount').to_i,
    'physical' => Facter.value('physicalprocessorcount').to_i,
    'speed'    => stats_cpu[:processors].collect{|i| i[:speed] }.compact.uniq.sort{|a,b| a.to_f <=> b.to_f }.last.to_f
  } rescue nil)
end
