Facter.add('uuid') do
  setcode do
    if not Facter.value('uuid').nil?
      Facter.value('uuid')
    elsif Facter::Util::Resolution.which('dmidecode')
      Facter::Util::Resolution.exec('dmidecode -s system-uuid').strip.chomp
    elsif File.exists?('/sys/hypervisor/uuid')
      File.read('/sys/hypervisor/uuid').lines.first.strip.chomp
    else
      nil
    end
  end
end

Facter.add('signature') do
  setcode do
    parts = []

    if Facter.value('uuid')
      parts << Facter.value('uuid').gsub(/[\W\_]+/,'').upcase
    end

    if Facter.value('macaddress')
      parts << Facter.value('macaddress').gsub(/[\W\_]+/,'').upcase
    end

  # still empty, now we really have to grasp at straws
    if parts.empty?
      if Facter.value('ipaddress')
        parts << Facter.value('ipaddress').split(',').first.strip.chomp.delete('.')
      end
    end


  # final pruning
    parts = parts.reject{|i| i.nil? || i.empty? }

  # still empty?
    if parts.empty?
      nil
    else
      parts.join('-')
    end
  end
end

Facter.add('hardwareid') do
  setcode do
  # 1. contents of /etc/hardware.id takes absolute precedence
    if File.size?('/etc/hardware.id')
      File.read('/etc/hardware.id').strip.chomp rescue nil

  # 2. value of kernel boot argument 'hardwareid' is checked
    elsif Facter.value('kernelarguments').is_a?(Hash) and not Facter.value('kernelarguments')['hardwareid'].nil?
      Facter.value('kernelarguments')['hardwareid']

  # 3. calculate a new hardwareid from the system signature
    elsif Facter.value('signature')
      require 'digest'
      Digest::SHA256.new.update(Facter.value('signature')).hexdigest[0..5]

  # 4. i got nothing...
    else
      nil
    end
  end
end
