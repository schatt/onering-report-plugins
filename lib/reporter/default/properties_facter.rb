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
    else (v.strip.chomp rescue v)
    end
  end

  if defined?(Facter)
  # get a list of Facter attributes to list
    local_list = File.join(File.dirname(File.dirname(File.dirname(__FILE__))),'etc','facter.list')

    facts = [
      local_list,
      "/etc/onering/facter.list"
    ].collect{|file|
      IO.readlines(file) if File.exists?(file)
    }.flatten.compact.sort.uniq


    facts.each do |line|
      Onering::Logger.debug3("-> Facter Line: #{line.inspect}", "Onering::Reporter")

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

          property(key.to_sym, val)
        rescue Exception => e
          Onering::Logger.debug(e.message, "onering-report-plugins/properties_facter/#{e.class.name}")
          next
        end
      end
    end
  end
end