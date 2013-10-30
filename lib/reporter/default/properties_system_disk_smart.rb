report do
  stat 'disk.@smart', Facter.value('smart')
end