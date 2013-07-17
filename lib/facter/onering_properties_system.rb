Facter.add('boottime') do
  setcode do
    Time.at(Time.now.to_i - Facter.value('uptime_seconds').to_i)
  end
end

Facter.add('kernelarguments') do
  setcode do
    if File.readable?('/proc/cmdline')
      Hash[File.read('/proc/cmdline').split(' ').collect{|i|
        key, value = i.split('=', 2)
        [key, value]
      }]
    else
      nil
    end
  end
end
