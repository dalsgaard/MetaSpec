require 'json'
require_relative 'lib/oas-dom'

class Parameter
  attr_reader :name, :in, :required

  def initialize(name, _in, required)
    @name = name
    @in = _in
    @required = required
  end

  def to_spec
    {
      name: @name,
      in: @in,
      required: @required
    }
  end
end

class RequestBody
  attr_reader :schema, :required

  def initialize(object)
    @required = !!object.required
    @schema = object.content['application/json'].schema if object.content
  end

  def to_spec
    {
      required: @required,
      schema: @schema&.data
    }
  end
end

class Response
  attr_reader :code

  def initialize(code, object)
    @code = code
    @content = !!object.content
  end

  def content?
    @content
  end
end

class Operation
  attr_reader :path, :method, :id, :parameters, :request_body, :responses

  def initialize(path, method, parameters, object)
    @path = path
    @method = method
    @id = object.operation_id
    @parameters = ((parameters || []) + (object.parameters || [])).map do |p|
      Parameter.new p.name, p.in, !!p.required
    end
    @request_body = object.request_body && RequestBody.new(object.request_body)
    @responses = object.responses.entries.map { |code, object| Response.new code.to_i, object }
  end

  def parameters_in
    @parameters.map(&:in).uniq
  end

  def to_spec
    {
      path: @path,
      method: @method,
      id: @id,
      parameters: @parameters.map(&:to_spec),
      requestBody: @request_body&.to_spec
    }
  end
end

data = JSON.parse(File.read('./examples/company.oas.json'))
oao = OasDom::OpenApiObject.new(data)

operations = []
oao.paths.entries.each do |path, pio|
  %i[get post put].each do |method|
    oo = pio.operation method
    next if oo.nil?

    path = path.gsub(/\{([^}]+)\}/) { ":#{Regexp.last_match(1)}" }

    operations << Operation.new(path, method, pio.parameters, oo)
  end
end

schema_types = oao.components.schemas.entries.map do |name, _|
  "export type #{name} = comps['schemas']['#{name}'];"
end

operation_types = operations.map do |op|
  name = op.id.sub(/^[a-z]/) { |ch| ch.upcase }
  ins = op.parameters_in.map { |i| "Required<ops['#{op.id}']['parameters']>['#{i}']" }
  if op.request_body
    type = "ops['#{op.id}']['requestBody']['content']['application/json']"
    opt = op.request_body.required ? '' : ' | undefined'
    req_body = type + opt
  else
    req_body = 'null'
  end
  responses = op.responses.map do |resp|
    body = resp.content? ? ", ops['#{op.id}']['responses']['#{resp.code}']['content']['application/json']" : ''
    "export type #{name}Response#{resp.code} = [#{resp.code}#{body}]"
  end
  res_types = op.responses.map { |resp| "#{name}Response#{resp.code}" }
  <<~OPTYPES
    export type #{name}Parameters = #{ins.empty? ? 'Record<PropertyKey, never>' : ins.join(' | ')};
    export type #{name}RequestBody = #{req_body};
    #{responses.join("\n")}
    export type #{name}Response = #{res_types.join(' | ')};
    export type #{name} = (parameters: #{name}Parameters, requestBody: #{name}RequestBody) => #{name}Response | Promise<#{name}Response>
  OPTYPES
end

schemas = oao.components.schemas.transform_values(&:data)
schemas['$id'] = 'http://specfirst.dev/schemas.json'

operations_json = JSON.pretty_generate(operations.map(&:to_spec))
operations_json.gsub!('"$ref": "#/components/schemas/', '"$ref": "http://specfirst.dev/schemas.json#/')

schemas_json = JSON.pretty_generate(schemas)
schemas_json.gsub!('"$ref": "#/components/schemas/', '"$ref": "#/')

puts <<~TYPES
  import { components as comps, operations as ops } from './company.d.ts';

  #{schema_types.join("\n")}

  #{operation_types.join("\n")}
  export const operations = #{operations_json} as const;

  export const schemas = #{schemas_json} as const;
TYPES
