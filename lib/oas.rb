require_relative 'spec'

using SpecRefinements

module OAS
  class Boolean
  end

  class SchemaObject
    fields :type?, :ref?

    before_field(:ref) do |value|
      value.is_a?(Symbol) ? "#/components/schemas/#{value}" : value
    end
  end

  class ReferenceObject
    fields :summary?, :description?
    field :ref, required: true, property: :$ref
  end

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

  class MediaTypeObject
    objects schema: SchemaObject
    argument_names(:schema, :ref)
  end

  class RequestBodyObject
    fields :description?, required?: Boolean
    objects content: { content: MediaTypeObject }
    map_shortcuts content: { json: 'application/json', xml: 'text/xml', plain: 'text/plain' }
    block_shortcuts json: { schema: :schema }
  end

  class ParameterObject
    fields :name, :in, :description?, required?: Boolean, deprecated: Boolean, allow_empty_value: Boolean
    fields :style?, explode?: Boolean, allow_reserved: Boolean
    objects schema: SchemaObject
    field_shortcuts in: { query: 'query', header: 'header', path: 'path', cookie: 'cookie' }
  end

  class OperationObject
    fields :summary?, :description?, :operation_id?, tags?: [String]
    objects request_body: RequestBodyObject
    objects parameters: [{ parameter: ParameterObject, parameter_ref: ReferenceObject }]

    before_object :request_body do |named_args|
      named_args[:required] = true unless named_args.include?(:required)
    end
    object_shortcuts request_body: { request_body?: { required: nil } }

    argument_names(:parameter, :name)
  end

  class PathItemObject
    fields :summary?, :description?
    objects get: OperationObject, post: OperationObject, put: OperationObject
  end

  class OpenAPIObject
    fields :openapi, :json_schema_dialect?
    objects info: InfoObject, paths: { path: PathItemObject }, servers: [{ server: ServerObject }]
  end

  init_spec OpenAPIObject
end
