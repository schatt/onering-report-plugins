if Facter::Util::Resolution.which('onering')
  onering = {}

  if defined?(Gem)
    if defined?(Gem::Specification)
      if Gem::Specification.respond_to?(:find_by_name)
        onering[:version] = Gem::Specification.find_by_name('onering-client').version.to_s
      end
    end
  end

  unless onering.empty?
    Facter.add('onering') do
      setcode { onering }
    end
  end
end
