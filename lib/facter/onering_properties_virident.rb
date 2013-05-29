if Facter::Util::Resolution.which('vgc-monitor')
  virident_cards = []

  Facter::Util::Resolution.exec("vgc-monitor | grep '^/dev'").split("\n").each do |card|
    name, partitions, model, status = card.strip.chomp.split(/\s+/)
    card = {
      :name       => name,
      :model      => model.strip,
      :status     => status.downcase,
      :driver     => {},
      :partitions => []
    }

    part = {}
    part_name = nil
    details = Facter::Util::Resolution.exec("vgc-monitor -d #{name}").split(/\n/).collect{|i| i.strip.split(/\s*:\s*/,2) }

    details.each_index do |i|
      detail = details[i]

      if detail.length == 2
        case detail.first
        when 'vgc-monitor'
          card[:driver][:tool_version] = detail.last

        # when 'Driver Uptime'
        #   card[:driver][:uptime] = detail.last

        when 'Serial Number'
          card[:serial] = detail.last

        when 'Temperature'
          card[:temperature] = detail.last.split(' ').first.to_i

        when 'Rev'
          card[:description] = detail.last

        when 'Card State Details'
          st = detail.last.downcase
          next if st == 'normal'
          card[:status_detail] = st

        when 'Action Required'
          action = detail.last.downcase
          next if action == 'none'
          card[:action_required] = action

      # partitions
        when 'Mode'
          part[part_name][:mode] = detail.last

        when 'Total Flash Bytes'
          part[part_name][:throughput] ||= {}
          part[part_name][:throughput][:read_bytes] = detail.last.split(' ').first.to_i
          part[part_name][:throughput][:write_bytes] = details[i+1].first.split(' ').first.to_i

        when 'Remaining Life'
          part[part_name][:life_remaining] = detail.last.delete('%').to_f

        when 'Partition State'
          part[part_name][:state] = detail.last.downcase

        when 'Flash Reserves Left'
          part[part_name][:reserves_remaining] = detail.last.delete('%').to_f

        end
      else
        if detail.first.to_s =~ /^\/dev\/(vgc[a-z]+[0-9]+)\s+([0-9]+) [KMGTPEZY]?B\s+([a-z]+)$/
          card[:partitions] << part unless part_name.nil?

          part_name = $1
          part[part_name] ||= {}
          part[part_name][:name] = part_name
          part[part_name][:size] = ($2.to_i * (1024 ** 3))
          part[part_name][:raid_enabled] = ($3 == 'enabled')
        end
      end

    end

    card[:partitions] << part unless part_name.nil?
    virident_cards << card
  end

  Facter.add("virident") do
    setcode do
      virident_cards
    end
  end
end
