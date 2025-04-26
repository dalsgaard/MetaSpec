require 'json'
require_relative 'lib/spec'

using SpecRefinements

module OAS
  class ContactObject
    fields :name?, :url?, :email?
  end

  class LicenseObject
    fields :name, :identifier?, :url?
  end

  class InfoObject
    fields :title, :summary?, :description?, :terms_of_service?, :version
    objects contact: ContactObject, license: LicenseObject
  end

  class ServerVariableObject
    fields :default, :description?, enum: [String]
  end

  class ServerObject
    fields :url, :description?
    objects variables: { variable: ServerVariableObject }
  end

  class RequestBodyObject
  end

  class OperationObject
    fields :summary?, :description?, :operation_id?, tags?: [String]
  end

  class PathItemObject
    fields :summary?, :description?
    objects get: OperationObject
  end

  class OpenAPIObject
    fields :openapi, :json_schema_dialect?
    objects info: InfoObject, paths: { path: PathItemObject }, servers: [:server, ServerObject]
  end

  init_spec OpenAPIObject
end

spec = OAS.spec do
  openapi '3.1'

  info title: 'Foo'

  server url: 'http://foo.bar/baz'

  path '/pets/{id}', description: 'A given pet' do
    get operation_id: :get_pet
  end
end

puts spec.openapi
puts spec.info.title

puts spec.paths['/pets/{id}'].description

puts spec.servers.first.url

File.write('foo.oas.json', JSON.pretty_generate(spec.to_spec))
