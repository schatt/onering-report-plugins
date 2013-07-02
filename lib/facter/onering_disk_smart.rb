if Facter::Util::Resolution.which('smartctl')
  disks = []
  letters = (('a'..'z').to_a + ('a'..'z').to_a.collect{|i| ('a'..'z').to_a.collect{|j| i+j }}.flatten)

  letters.each do |i|
    if File.exists?("/dev/sd#{i}")
      smart = {}

      Facter::Util::Resolution.exec("smartctl -A /dev/sd#{i}").to_s.lines.each do |line|
        next unless line =~ /^\s*[0-9]+/
        id, name, flag, value, worst, threshold, type, updated, failed, raw = line.strip.chomp.split(/\s+/)

        smart[:attributes] ||= []
        smart[:attributes] << {
          :id        => id.to_i,
          :name      => name.downcase.gsub(/[\s\-]+/, '_'),
          :value     => value.to_i,
          :worst     => worst.to_i,
          :threshold => threshold.to_i,
          :type      => type.downcase,
          :raw       => raw
        }
      end

      smart[:name] = "/dev/sd#{i}"
      
      disks << smart
    end
  end

  disks = disks.reject{|i| (i[:attributes] || {}).empty? }
 
  unless disks.empty?
    Facter.add('smart') do
      setcode { disks }
    end
  end
end
