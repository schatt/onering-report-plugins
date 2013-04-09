# Onering Facts - Chef Properties
#   provides collection of Chef metadata
#
require 'json'

chef = Facter::Util::Resolution.exec("knife node show $(hostname -f) -c /etc/chef/client.rb -k /etc/chef/client.pem -u $(hostname -f) -F json 2> /dev/null | grep -v 'json_class' 2> /dev/null")


if chef
  begin
    chef = (JSON.load(chef) rescue {})

    unless chef.empty?
      Facter.add('chef_nodename') do
        setcode { chef['name'].to_s.strip.chomp.downcase rescue nil }
      end

      Facter.add('chef_version') do
        setcode { %x{chef-client --version}.chomp.split(' ').last.strip rescue nil }
      end

      Facter.add('chef_environment') do
        setcode { chef['environment'].to_s.strip.chomp.downcase rescue nil }
      end

      Facter.add('chef_runlist') do
        setcode { chef['run_list'].collect{|i| i.gsub('[','-').gsub(']','').gsub('::','-') } rescue nil }
      end

      Facter.add('chef_enabled') do
        setcode { !File.exists?('/outbrain/no_chef_run') }
      end

      Facter.add('chef_lastrun') do
        setcode { File.mtime('/etc/chef/last_ran_at').to_i rescue nil }
      end
    end
  rescue Exception => e
    STDERR.puts "#{e.name}: #{e.message}"
  end
end
