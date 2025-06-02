require_relative 'spec'
require_relative 'http-status'
require_relative 'schema'

using SpecRefinements

module OAS
  class ReferenceObject
    fields :summary?, :description?
    field :ref, required: true, property: :$ref
  end

  class ParameterReferenceObject < ReferenceObject
    before_field(:ref) do |value|
      value.is_a?(Symbol) ? "#/components/parameters/#{value}" : value
    end
  end

  class ResponseReferenceObject < ReferenceObject
    before_field(:ref) do |value|
      value.is_a?(Symbol) ? "#/components/responses/#{value}" : value
    end
  end

  class HeaderReferenceObject < ReferenceObject
    before_field(:ref) do |value|
      value.is_a?(Symbol) ? "#/components/headers/#{value}" : value
    end
  end

  class LinkReferenceObject < ReferenceObject
    before_field(:ref) do |value|
      value.is_a?(Symbol) ? "#/components/links/#{value}" : value
    end
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

    argument_names schema: :ref
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
    objects schema: SchemaObject, content: { content: MediaTypeObject }

    field_shortcuts in: { query: 'query', header: 'header', path: 'path', cookie: 'cookie' }
  end

  class HeaderObject
    fields :description?, required?: Boolean, deprecated?: Boolean
    fields :style?, explode?: Boolean
    objects schema: SchemaObject, content: { content: MediaTypeObject }
  end

  class LinkObject
    fields :operation_ref?, :operation_id?, :description?
  end

  class ResponseObject
    fields :description, required: Boolean, deprecated: Boolean
    objects headers: { header: HeaderObject, header_ref: HeaderReferenceObject }
    objects content: { content: MediaTypeObject }
    objects links: { link: LinkObject, link_ref: LinkReferenceObject }

    map_shortcuts content: { json: 'application/json', xml: 'text/xml', plain: 'text/plain' }
    block_shortcuts json: { schema: :schema }
  end

  class OperationObject
    fields :summary?, :description?, :operation_id?, tags?: [String]
    objects request_body: RequestBodyObject
    objects parameters: [{ parameter: ParameterObject, parameter_ref: ParameterReferenceObject }]
    objects responses: { response: ResponseObject, response_ref: ResponseReferenceObject }

    before_object :request_body do |*args, **named_args|
      named_args[:required] = true unless named_args.include?(:required)
      [args, named_args]
    end
    object_shortcuts request_body: { request_body?: { required: nil } }

    before_key(:response) do |key = nil|
      key.nil? ? :default : key
    end

    argument_names parameter: :name, response_ref: [nil, :ref], parameter_ref: :ref
  end

  class PathItemObject
    fields :summary?, :description?
    objects get: OperationObject, post: OperationObject, put: OperationObject
  end

  class ComponentsObject
    objects schemas: { schema: SchemaObject }
  end

  class OpenAPIObject
    include HttpStatus

    fields :openapi, :json_schema_dialect?
    objects info: InfoObject, paths: { path: PathItemObject }, servers: [{ server: ServerObject }]
    objects components: ComponentsObject

    class Boolean
    end

    class Number
    end
  end

  init_spec OpenAPIObject
end
