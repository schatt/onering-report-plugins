# Onering Facts - Service List
#   provides list of certain services that are running on a machine
#


Facter.add('services') do
  def get_service_list()
    rv = []
    case Facter.value('osfamily')
    when 'Debian'
      rv = IO.popen('find /etc/init.d -maxdepth 1 -type f -executable | cut -d"/" -f4 | sort | uniq').lines
    when 'RedHat'
      rv = IO.popen('chkconfig --list | grep "3:on" | tr "\t" " " | cut -d" " -f1 | sort | uniq').lines
    end

    rv.collect {|i| i.strip.chomp }.reject{|i| i.empty? }
  end

  setcode do
    acceptable = (File.read('/etc/onering/services.list').lines.collect{|i| i.strip.chomp }.reject{|i| i.empty? } rescue [])
    actual     = get_service_list()

    (acceptable & actual)
  end
end
