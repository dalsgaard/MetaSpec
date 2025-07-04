require_relative 'spec'
require_relative 'http-status'
require_relative 'schema'

using SpecRefinements

module OAS
  class ReferenceObject
    fields :summary?, :description?
    field :ref, required: true, property: :$ref

    alias desc description
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

    alias desc description
  end

  class ServerVariableObject
    fields :default, :description?, enum: [String]

    alias desc description
  end

  class ServerObject
    fields :url, :description?
    objects variables: { variable: ServerVariableObject }

    alias desc description
  end

  class MediaTypeObject
    objects schema: SchemaObject

    # argument_names schema: :ref
    before_object :schema do |args, named_args, block|
      case args.first
      when Array
        type = args.shift.first
        args.unshift type
        schema type: Array do
          items(*args, **named_args, &block)
        end
        nil
      when Class
        named_args[:type] = args.shift
        [args, named_args]
      else
        named_args[:ref] = args.shift
        [args, named_args]
      end
    end
  end

  class RequestBodyObject
    fields :description?, required?: Boolean
    objects content: { content: MediaTypeObject }

    map_shortcuts content: { json: 'application/json', xml: 'text/xml', plain: 'text/plain' }
    block_shortcuts json: { schema: :schema }

    alias desc description
  end

  class ParameterObject
    fields :name, :in, :description?, required?: Boolean, deprecated: Boolean, allow_empty_value: Boolean
    fields :style?, explode?: Boolean, allow_reserved: Boolean, example: Any
    objects schema: SchemaObject, content: { content: MediaTypeObject }

    field_shortcuts in: { query: 'query', header: 'header', path: 'path', cookie: 'cookie' }

    argument_names schema: :type

    before_field :in do |value|
      if value.to_s == 'path'
        required true
        schema(type: String) if schema.nil?
      elsif value.to_s == 'query'
        schema(type: String) if schema.nil?
      end
      value
    end

    alias desc description
  end

  class HeaderObject
    fields :description?, required?: Boolean, deprecated?: Boolean
    fields :style?, explode?: Boolean
    objects schema: SchemaObject, content: { content: MediaTypeObject }

    alias desc description
  end

  class LinkObject
    fields :operation_ref?, :operation_id?, :description?

    alias desc description
    alias oid operation_id
  end

  class ResponseObject
    fields :description, required: Boolean, deprecated: Boolean
    objects headers: { header: HeaderObject, header_ref: HeaderReferenceObject }
    objects content: { content: MediaTypeObject }
    objects links: { link: LinkObject, link_ref: LinkReferenceObject }

    map_shortcuts content: { json: 'application/json', xml: 'text/xml', plain: 'text/plain' }
    block_shortcuts json: { schema: :schema }

    alias desc description
  end

  class OperationObject
    fields :summary?, :description?, :operation_id?, tags?: [String]
    objects request_body: RequestBodyObject
    objects parameters: [{ parameter: ParameterObject, parameter_ref: ParameterReferenceObject }]
    objects responses: { response: ResponseObject, response_ref: ResponseReferenceObject }

    before_object :request_body do |args, named_args|
      named_args[:required] = true unless named_args.include?(:required)
      [args, named_args]
    end
    object_shortcuts request_body: { request_body?: { required: nil } }

    before_key(:response) do |key = nil|
      key.nil? ? :default : key
    end

    argument_names parameter: :name, response_ref: [nil, :ref], parameter_ref: :ref

    alias desc description
    alias oid operation_id
  end

  class PathItemObject
    fields :summary?, :description?
    objects get: OperationObject, post: OperationObject, put: OperationObject
    objects parameters: [{ parameter: ParameterObject, parameter_ref: ParameterReferenceObject }]

    argument_names parameter: :name, parameter_ref: :ref

    alias desc description
  end

  class SecurityRequirementObject
    def initialize(requirement: nil, &block)
      @requirements = {}
      @requirements[requirement] = [] unless requirement.nil?
      instance_eval(&block) if block
    end

    def requirement(name, list = [])
      @requirements[name] = list
    end

    def to_spec
      @requirements
    end
  end

  class SecuritySchemeObject
    fields :type, :description?, :name?, :in?, :scheme?, :bearer_format?, :open_id_connect_url?
  end

  class ComponentsObject
    objects schemas: { schema: SchemaObject }
    objects security_schemes: { security_scheme: SecuritySchemeObject }
  end

  class OpenAPIObject
    include HttpStatus

    fields :openapi, :json_schema_dialect?
    objects info: InfoObject, paths: { path: PathItemObject }, servers: [{ server: ServerObject }]
    objects components: ComponentsObject
    objects security: [{ security: SecurityRequirementObject }]

    class Any
    end

    class Boolean
    end

    class Number
    end
  end

  init_spec OpenAPIObject
end
