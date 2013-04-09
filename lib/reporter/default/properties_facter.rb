# Onering Collector - Facter Properties plugin
#   provides a configurable list of Facter facts that should be sent to the
#   Onering API
#
#   Properties defined in /etc/onering/facter.list
#

report do
  def cleanup_dirty_values(k, v)
    return case k
    when 'mbserial' then v.to_s.gsub(/(^\.+|\.+$)/,'').gsub('.','-')
    else (v.strip.chomp rescue nil)
    end
  end

  if defined?(Facter)
  # get a list of Facter attributes to list
    if File.exists?("/etc/onering/facter.list")
      IO.readlines("/etc/onering/facter.list").each do |line|
      # strip whitespace/kill newline
        line.strip!
        line.chomp!
        next if line.empty?
        line = line.downcase

        unless line =~ /^#/
          begin
            line = line.split(':')
            key = (line.length == 1 ? line.first : line.last)
            val = cleanup_dirty_values(key, Facter.value(line.first))

            property key.to_sym, val
          rescue Exception
            STDERR.puts e.message
            next
          end
        end
      end
    end
  end
end