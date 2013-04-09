# Onering Collector - Ohai Properties plugin
#   provides a configurable list of Ohai attributes that should be sent to the
#   Onering API
#
#   Properties defined in /etc/onering/ohai.list
#

report do
  if defined?(Ohai)
    def cleanup_dirty_values(k, v)
      return case k
      when 'mbserial' then v.to_s.gsub(/(^\.+|\.+$)/,'').gsub('.','-')
      else v
      end
    end

    # get a list of ohai attributes to list
    if File.exists?("/etc/onering/ohai.list")
      IO.readlines("/etc/onering/ohai.list").each do |line|
      # trip whitespace/kill newline
        line.strip!
        line.chomp!
        next if line.empty?
        line = line.downcase

        unless line =~ /^#/
          begin
            parts = line.split(".")
            root = @ohai

            parts.each do |part|
              part = part.split(':')
              key = part.first
              alt = part.last

              if root[key]
                if root[key].is_a?(Hash)
                  root = root[key]
                  next
                else
                  val = [*root[key]].collect{|i| i.strip.chomp rescue i }
                  val = val.first if val.length == 1
                  val = cleanup_dirty_values(alt, val)
                  val.strip! if val.is_a?(String)

                # set property value
                  property alt, val
                  break
                end
              else
                break
              end
            end
          rescue Exception
            STDERR.puts e.message
            next
          end
        end
      end
    end
  end
end