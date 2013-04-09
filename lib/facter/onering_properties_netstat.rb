require 'resolv'

protocols = %w{tcp}

flags = "--numeric-hosts --numeric-ports --programs --tcp -ee"

case Facter.value('osfamily').to_s.downcase
when 'debian' then flags += " -W"
when 'redhat' then flags += " -T"
end

listening = Facter::Util::Resolution.exec("netstat #{flags} -l | tr -s ' '")
nonlistening = Facter::Util::Resolution.exec("netstat #{flags} | tr -s ' '")

netstat = {
  'listening'    => [],
  'connections'  => []
}

def getcommandline(pid)
  return nil unless pid.to_i > 0
  (File.read("/proc/#{pid}/cmdline").to_s.strip.chomp.squeeze("\u0000").squeeze("\0").gsub("\u0000", ' ').gsub("\0", ' '))
end

listening.lines.to_a[2..-1].each do |line|
  protocol, recvq, sendq, local, foreign, state, user, inode, program = line.split(' ', 9)
  next unless protocols.include?(protocol)

  local = local.split(':')
  foreign = foreign.split(':')
  local_host = local[-2]
  local_port = local[-1]
  foreign_host = foreign[-2]
  foreign_port = foreign[-1]
  pid = program.split('/').first

  netstat['listening'] << {
    "protocol" => protocol,
    "address"  => local_host,
    "fqdn"     => (Resolv.getname(local_host) rescue nil),
    "port"     => local_port.to_i,
    "user"     => user,
    "program"  => {
      "pid"     => pid.to_i,
      "command" => getcommandline(pid)
    }
  }
end

nonlistening.lines.to_a[2..-1].each do |line|
  protocol, recvq, sendq, local, foreign, state, user, inode, program = line.split(' ', 9)
  next unless protocols.include?(protocol)

  local = local.split(':')
  foreign = foreign.split(':')
  local_host = local[-2]
  local_port = local[-1]
  foreign_host = foreign[-2]
  foreign_port = foreign[-1]
  pid = program.split('/').first

  netstat['connections'] << {
    "protocol" => protocol,
    "from" => {
      "address" => local_host,
      "port"    => local_port.to_i
    },
    "to" => {
      "address" => foreign_host,
      "fqdn"    => (Resolv.getname(foreign_host) rescue nil),
      "port"    => foreign_port.to_i
    },
    "user"  => user,
    "state" => state.downcase,
    "program" => {
      "pid"     => pid.to_i,
      "command" => getcommandline(pid)
    }
  }
end

Facter.add("netstat") do
  setcode do
    netstat
  end
end
