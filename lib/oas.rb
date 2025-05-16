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

    before_object :schema do |named_args, ref = nil|
      named_args[:ref] = ref if !ref.nil? && named_args[:ref].nil?
    end
  end

  class RequestBodyObject
    fields :description?, required?: Boolean
    objects content: { content: MediaTypeObject }
    map_shortcuts content: { json: 'application/json', xml: 'text/xml', plain: 'text/plain' }
    block_shortcuts json: { schema: :schema }
  end

  class OperationObject
    fields :summary?, :description?, :operation_id?, tags?: [String]
    objects request_body?: RequestBodyObject
    object_shortcuts request_body?: { request_body: { required: true } }
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
