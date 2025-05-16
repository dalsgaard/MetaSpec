require 'json'
require_relative 'lib/oas'

Dir.glob(ARGV[0]).each do |input|
  output = input.sub(/\.rb$/, '.json')
  content = File.read(input)
  spec = OAS.spec content
  File.write(output, JSON.pretty_generate(spec.to_spec))
end
