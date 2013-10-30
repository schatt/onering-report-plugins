report do
# ------------------------------------------------------------------------------
# block devices
#
  blocks = []

  Facter.value('blockdevices').split(/\W+/).each do |dev|

    block = {
      :name   => dev,
      :device => (File.exists?("/dev/#{dev}") ? "/dev/#{dev}" : nil),
      :vendor => Facter.value("blockdevice_#{dev}_vendor"),
      :model  => Facter.value("blockdevice_#{dev}_model"),
      :size   => (Integer(Facter.value("blockdevice_#{dev}_size")) rescue nil)
    }

    if File.directory?("/sys/block/#{dev}")
      block[:removable]  = (File.read("/sys/block/#{dev}/removable").to_s.chomp.strip == '1' rescue nil)
      block[:readonly]   = (File.read("/sys/block/#{dev}/ro").to_s.chomp.strip == '1' rescue nil)
      block[:solidstate] = (File.read("/sys/block/#{dev}/queue/rotational").to_s.chomp.strip == '0' rescue nil)
      block[:sectorsize] = {}

      %w{
        logical
        physical
      }.each do |s|
        block[:sectorsize][s.to_sym] = (Integer(File.read("/sys/block/#{dev}/queue/#{s}_block_size").chomp.strip) rescue nil)
      end
    end

    blocks << block.compact
  end

  stat 'disk.@block', blocks unless blocks.empty?
end