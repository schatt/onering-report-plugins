Facter.add('signature') do
  setcode do
    if Facter.value('macaddress')
      if Facter.value('is_virtual')
        if File.exists?('/sys/hypervisor/uuid')
          parts = [
            File.read('/sys/hypervisor/uuid').strip.chomp.delete('-'),
            Facter.value('macaddress').strip.delete(':')
          ]
        end
      elsif Facter::Util::Resolution.which('dmidecode')
        parts = [
          Facter::Util::Resolution.exec('dmidecode -s system-uuid').strip.chomp.delete('-'),
          Facter.value('macaddress').strip.delete(':')
        ]
      end
    end

    (parts ? parts.collect{|i| i.upcase }.join('-') : nil)
  end
end

Facter.add('hardwareid') do
  setcode do
    if File.size?('/etc/hardware.id')
      File.read('/etc/hardware.id').strip.chomp rescue nil
    elsif Facter.value('signature')
      require 'digest'
      Digest::SHA256.new.update(Facter.value('signature')).hexdigest[0..5]
    end
  end
end
