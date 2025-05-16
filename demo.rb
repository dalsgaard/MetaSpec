require 'json'
require_relative 'lib/oas'

spec = OAS.spec do
  openapi '3.1'

  info title: 'Foo'

  server url: 'http://foo.bar/baz'

  path '/pets/{id}', description: 'A given pet' do
    get operation_id: :get_pet do
      request_body schema: :Pet
    end
  end
end

File.write('foo.oas.json', JSON.pretty_generate(spec.to_spec))
