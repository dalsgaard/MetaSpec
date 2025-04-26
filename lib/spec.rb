module SpecRefinements
  class FieldDesc
    attr_reader :name, :type, :required, :default

    def initialize(name, type, required, default: nil, array: false, map: false)
      @name = name
      @type = type
      @required = required
      @default = default
      @array = array
      @map = map
    end

    def array? = @array
    def map? = @map
  end

  class ObjectDesc
    attr_reader :name, :type, :required

    def initialize(name, type, required, array: false, map: false)
      @name = name
      @type = type
      @required = required
      @array = array
      @map = map
    end

    def array? = @array
    def map? = @map
  end

  module BaseObject
    def initialize(**named_args, &block)
      named_args.entries.each do |property, value|
        send property, value
      end
      instance_eval(&block) if block
    end

    def to_spec
      spec = {}
      if self.class.class_variable_defined? :@@fields
        fields = self.class.class_variable_get :@@fields
        fields.each do |field|
          value = instance_variable_get "@#{field.name}"
          spec[field.name] = value unless value.nil?
        end
      end
      if self.class.class_variable_defined? :@@objects
        objects = self.class.class_variable_get :@@objects
        objects.each do |object|
          value = instance_variable_get "@#{object.name}"
          next if value.nil?

          spec[object.name] = if object.array?
                                value.map(&:to_spec)
                              elsif object.map?
                                value.transform_values(&:to_spec)
                              else
                                puts object.name, value
                                value.to_spec
                              end
        end
      end
      spec
    end
  end

  refine Module do
    def init_spec(root)
      @root = root
      constants.each do |const_name|
        const = const_get(const_name)
        const.include BaseObject if const.instance_of? Class
      end
      module_eval do
        def self.spec(&block)
          @root.new(&block)
        end
      end
    end
  end

  refine Class do
    def field(name, type, required: nil)
      name, q = name.match(/^([^?]+)(\?)?$/).captures
      required = required.nil? ? !q : required
      fields = class_variable_defined?(:@@fields) ? class_variable_get(:@@fields) : class_variable_set(:@@fields, [])
      fields << FieldDesc.new(name, type, required)
      define_method(name) do |value = nil|
        if value.nil?
          instance_variable_get "@#{name}"
        else
          instance_variable_set "@#{name}", value
        end
      end
    end

    def fields(*args, **named_args)
      if args.empty? && named_args.empty?
        @fields
      else
        args.each do |name|
          field(name, String)
        end
        named_args.each_pair do |name, type|
          field(name, type)
        end
      end
    end

    def objects(**named_args)
      objects = if class_variable_defined?(:@@objects)
                  class_variable_get(:@@objects)
                else
                  class_variable_set(:@@objects,
                                     [])
                end
      named_args.each_pair do |name, type|
        case type
        when Hash
          add_name, type = type.entries.first
          objects << ObjectDesc.new(name, type, false, map: true)
          define_method(name) do
            instance_variable_get "@#{name}"
          end
          define_method(add_name) do |key, **named_args, &block|
            map = instance_variable_get "@#{name}"
            map ||= instance_variable_set "@#{name}", {}
            value = type.new(**named_args, &block)
            map[key] = value
          end
        when Array
          add_name, type = type
          objects << ObjectDesc.new(name, type, false, array: true)
          define_method(name) do
            instance_variable_get "@#{name}"
          end
          define_method(add_name) do |**named_args, &block|
            list = instance_variable_get "@#{name}"
            list ||= instance_variable_set "@#{name}", []
            value = type.new(**named_args, &block)
            list << value
          end
        else
          objects << ObjectDesc.new(name, type, false)
          define_method(name) do |**named_args, &block|
            if block.nil? && named_args.empty?
              instance_variable_get "@#{name}"
            else
              value = type.new(**named_args, &block)
              instance_variable_set "@#{name}", value
            end
          end
        end
      end
    end
  end
end
