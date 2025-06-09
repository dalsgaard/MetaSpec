require_relative 'spec'

using SpecRefinements

module OAS
  class Boolean
  end

  class Number
  end

  class Any
  end

  class SchemaObject
    fields :type?, :format?, minimum?: Integer, maximum: Integer, mim_items: Integer
    field :ref, required: false, property: :$ref
    fields required: [String], enum: []
    field :examples, nil, required: false, array: true

    field_or_object :additional_properties, Boolean, SchemaObject
    field_or_object :items, Boolean, SchemaObject
    field_or_object :unevaluated_items, Boolean, SchemaObject

    objects properties: { property: SchemaObject }, pattern_properties: { pattern_property: SchemaObject }

    objects prefix_items: [{ prefix_item: SchemaObject }]
    objects contains: SchemaObject

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

    before_object :items do |args, named_args, _block|
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
      when Symbol
        named_args[:ref] = args.shift
        [args, named_args]
      else
        [args, named_args]
      end
    end

    def refs(**named_args)
      named_args.each_pair do |name, type|
        property name, ref: type
      end
    end

    alias p property
    alias prop property
  end
end
