require_relative 'spec-dom'

module OasDom
  include SpecDom

  class SchemaObject
    attr_reader :data

    def initialize(data)
      @data = data
    end
  end

  class ReferenceObject < DomObject
    fields :$ref, :description, :summary
  end

  class ServerVariableObject < DomObject
    fields :enum, :default, :description
  end

  class ServerObject < DomObject
    fields :url, :description
    maps variables: ServerVariableObject
  end

  class ParameterObject < DomObject
    fields :name, :in, :description, :required, :deprecated, :allowEmptyValue
    objects schema: SchemaObject
  end

  class ExternalDocumentationObject
    fields :url, :description
  end

  class MediaTypeObject < DomObject
    objects schema: SchemaObject
  end

  class RequestBodyObject < DomObject
    fields :required
    maps content: MediaTypeObject
  end

  class ResponseObject < DomObject
    fields :description
    maps content: MediaTypeObject
  end

  class CallbackObject < DomObject
  end

  class SecurityRequirementObject
  end

  class OperationObject < DomObject
    fields :tags, :description, :summary, :operationId, :deprecated
    objects externalDocs: ExternalDocumentationObject
    objects parameters: [{ nil => ParameterObject, :$ref => ReferenceObject }]
    objects requestBody: { nil => RequestBodyObject, :$ref => ReferenceObject }
    objects security: [SecurityRequirementObject], servers: [ServerObject]
    maps responses: { nil => ResponseObject, :$ref => ReferenceObject }
    maps callbacks: { nil => CallbackObject, :$ref => ReferenceObject }
  end

  class PathItemObject < DomObject
    fields :$ref, :description, :summary
    objects servers: [ServerObject]
    objects get: OperationObject, post: OperationObject, put: OperationObject, delete: OperationObject
    objects options: OperationObject, head: OperationObject, patch: OperationObject, trace: OperationObject
    objects parameters: [{ nil => ParameterObject, :$ref => ReferenceObject }]

    def operation(method)
      send method
    end
  end

  class ComponentsObject < DomObject
    maps schemas: SchemaObject
  end

  class ContactObject < DomObject
    fields :name, :url, :email
  end

  class LicenseObject < DomObject
    fields :name, :url, :identifier
  end

  class InfoObject < DomObject
    fields :title, :version, :description, :summary, :termsOfService
    objects contact: ContactObject, license: LicenseObject
  end

  class OpenApiObject < DomObject
    fields :openapi, :jsonSchemaDialect
    objects info: InfoObject, servers: [ServerObject]
    maps paths: PathItemObject
    objects components: ComponentsObject
  end
end
