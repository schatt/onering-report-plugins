Facter.add('boottime') do
  setcode do
    Time.at(Time.now.to_i - Facter.value('uptime_seconds').to_i)
  end
end
