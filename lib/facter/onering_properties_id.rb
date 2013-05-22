Facter.add('signature') do
  setcode do
    if File.size?("/etc/onering/signature")
      parts = File.read("/etc/onering/signature").split("\n").
                reject{|i| i =~ /^\s*#/ }.
                reject{|i| i.strip.chomp.empty? }.
                collect{|i| i.gsub(/\H/,'') }

    elsif Facter.value('macaddress')
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

    else
      if Facter.value('ipaddress')
        parts = [
          Facter.value('ipaddress').split(',').first.strip.chomp.delete('.')
        ].compact
      end
    end

    (parts && !parts.empty? ? parts.collect{|i| i.upcase }.join('-') : nil)
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
