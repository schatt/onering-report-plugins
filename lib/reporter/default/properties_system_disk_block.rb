report do
# ------------------------------------------------------------------------------
# block devices
#
  blocks = []

  Facter.value('blockdevices').to_s.split(/\W+/).each do |dev|

    block = {
      :name   => dev,
      :device => (File.exists?("/dev/#{dev}") ? "/dev/#{dev}" : nil)
    }

    if File.directory?("/sys/block/#{dev}")
      block[:vendor]     = (%x{cat /sys/block/#{dev}/device/vendor 2> /dev/null}.to_s.strip.chomp rescue nil)
      block[:model]      = (%x{cat /sys/block/#{dev}/device/model 2> /dev/null}.to_s.strip.chomp rescue nil)
      block[:size]       = ((Integer(%x{cat /sys/block/#{dev}/size 2> /dev/null}.to_s.strip.chomp) * 512) rescue nil)
      block[:removable]  = (%x{cat /sys/block/#{dev}/removable 2> /dev/null}.to_s.chomp.strip == '1' rescue nil)
      block[:readonly]   = (%x{cat /sys/block/#{dev}/ro 2> /dev/null}.to_s.chomp.strip == '1' rescue nil)
      block[:solidstate] = (%x{cat /sys/block/#{dev}/queue/rotational 2> /dev/null}.to_s.chomp.strip == '0' rescue nil)
      block[:sectorsize] = {}

      %w{
        logical
        physical
      }.each do |s|
        block[:sectorsize][s.to_sym] = (Integer(%x{cat /sys/block/#{dev}/queue/#{s}_block_size 2> /dev/null}.chomp.strip) rescue nil)
      end
    end

    blocks << block.compact
  end

  stat 'disk.@block', blocks
end
