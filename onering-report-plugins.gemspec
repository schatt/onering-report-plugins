Gem::Specification.new do |s|
  s.name        = "onering-report-plugins"
  s.version     = "0.0.8"
  s.date        = "2013-04-09"
  s.summary     = "Onering system reporting plugins"
  s.description = "Base plugins for providing system information via the Onering client utility"
  s.authors     = ["Gary Hetzel"]
  s.email       = "ghetzel@outbrain.com"
  s.files       = Dir['lib/**/*'].select{|i| i =~ /\.rb$/ }
  s.homepage    = "https://github.com/outbrain/onering-report-plugins"

  %w{
    onering-client
  }.each do |g|
    s.add_runtime_dependency g
  end
end
