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
# memory (hardware)
#
  mode = nil
  slot = nil
  nilrx = /^(?:\s+|none|undefined|0+)$/

  IO.popen("dmidecode -t memory").lines.each do |line|
    case line.chomp
    when /^Physical Memory Array$/
      mode = :controller
      next
    when /^Memory Device$/
      mode = :dimm
      stats_mem[:slots] ||= []
      slot = {}
      next

  # subvalues
    when /^\t([^\:]+): (.+)$/
      key = $1.strip
      value = $2.strip

      case mode
      when :controller
        case key.upcase
        when 'ERROR CORRECTION TYPE'
          stats_mem[:ecc] = (value.downcase == 'none' ? false : true)
          stats_mem[:ecc_type] = value.downcase.gsub('ecc','').strip.gsub(/[\W\s]+/,'_') if stats_mem[:ecc]

        when 'NUMBER OF DEVICES'
          i = Integer(value.strip) rescue nil
          stats_mem[:slot_count] = i unless i.nil?

        when 'MAXIMUM CAPACITY'
          stats_mem[:capacity] = value.to_s.to_bytes

        else
          next
        end

      when :dimm
        case key.upcase
        when 'SIZE'
          slot[:size] = value.to_s.to_bytes
        when 'TYPE'
          slot[:type] = value.strip
        when 'BANK LOCATOR'
          slot[:bank] = value.strip
        when 'LOCATOR'
          slot[:id] = value.strip
        when 'SERIAL NUMBER'
          slot[:serial] = (value.strip.downcase =~ nilrx ? nil : value)
        when 'MANUFACTURER'
          slot[:make] = (value.downcase =~ nilrx ? nil : value)
        when 'PART NUMBER'
          slot[:model] = (value.downcase =~ nilrx ? nil : value)
        when 'SPEED'
          slot[:speed] = value.split(/\s+/).first.to_i
        when 'RANK'
          slot[:rank] = (Integer(value) rescue nil)
          slot[:empty] = false unless slot[:rank].nil?

        else
          next
        end
      else
        next
      end

    when ''
      if mode == :dimm and not slot.empty?
        if slot[:rank].nil?
          slot = {
            :id    => slot[:id],
            :name  => slot[:name],
            :bank  => slot[:bank],
            :empty => true
          }
        end

        stats_mem[:slots] << slot.compact
      end
    end
  end

  unless stats_mem[:slots].nil?
    begin
      stats_mem[:slots] = stats_mem[:slots].sort_by{|k,v| v[:id] unless v.nil? }
    rescue
      nil
    end
  end

  stat :memory, stats_mem
end