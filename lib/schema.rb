require_relative 'spec'

using SpecRefinements

module OAS
  class Boolean
  end

  class Number
  end

  class SchemaObject
    fields :type?
    field :ref, required: false, property: :$ref
    fields additional_properties: Boolean, required: [String]

    objects properties: { property: SchemaObject }, pattern_properties: { pattern_property: SchemaObject }

    objects items: SchemaObject, prefix_items: [{ prefix_item: SchemaObject }]

    objects all_of: [{ all_of: SchemaObject }], any_of: [{ any_of: SchemaObject }]
    objects one_of: [{ one_of: SchemaObject }]

    before_field(:ref) do |value|
      value.is_a?(Symbol) ? "#/components/schemas/#{value}" : value
    end

    object_shortcuts property: {
      object: { type: Object },
      array: { type: Array },
      string: { type: String },
      integer: { type: Integer },
      number: { type: Number }
    }

    before_key(:property) do |key|
      n, q = key.match(/^([^?]+)(\?)?$/).captures
      required n unless q
      n
    end

    before_field(:type) do |type|
      if type.is_a? Class
        case type.name.split('::').last
        when 'String'
          :string
        when 'Number'
          :number
        when 'Integer'
          :integer
        when 'Array'
          :array
        when 'Object'
          :object
        else
          type
        end
      else
        type
      end
    end

    argument_names items: :type
  end
end
