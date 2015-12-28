Gem::Specification.new do |s|
  s.name        = 'csv_sniffer'
  s.version     = '0.1.2'
  s.date        = '2015-12-28'
  s.summary     = "CSV library for heuristic detection of CSV properties"
  s.description = "CSV Sniffer is a set of functions that allow a user detect the delimiter character in use, whether the values in the CSV file are quote enclosed, whether the file contains a header, and more. The library is intended to detect information to be used as configuration inputs for CSV parsers."
  s.authors     = ["Tim Ojo"]
  s.email       = 'ojo.tim@gmail.com'
  s.homepage    = 'https://github.com/tim-ojo/csv_sniffer'
  s.license     = 'MIT'

  s.files       = `git ls-files`.split($/)
  s.test_files  = s.files.grep(/^test/)
  s.add_development_dependency 'test-unit', '~> 0'
end
