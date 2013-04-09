# Onering Collector - Chef Properties plugin
#   provides collection of Chef metadata
#
report do
  chef = {
    :name        => Facter.value('chef_nodename'),
    :environment => Facter.value('chef_environment'),
    :@run_list   => Facter.value('chef_runlist'),
    :enabled     => Facter.value('chef_enabled'),
    :version     => Facter.value('chef_version'),
    :last_ran_at => (Time.at(Facter.value('chef_lastrun')) rescue nil)
  }.reject{|k,v| v === nil }

  property :chef, chef unless chef.empty?
end
