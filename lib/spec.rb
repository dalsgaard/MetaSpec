def iname(name)
  "@#{name.to_s.delete_suffix('?')}"
end

def pname(name)
  name.to_s.delete_suffix('?').gsub(/_([a-z])/) { Regexp.last_match(1).upcase }
end

module SpecRefinements
  class FieldDesc
    attr_reader :name, :type, :required, :default, :property

    def initialize(name, type, required, property, default: nil, array: false, map: false)
      @name = name
      @property = pname(property || name)
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
    attr_reader :name, :type, :required, :property

    def initialize(name, type, required, array: false, map: false)
      @name = name
      @property = pname(name)
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
        send property, value unless value.nil?
      end
      instance_eval(&block) if block
    end

    def to_spec
      spec = {}
      if self.class.class_variable_defined? :@@fields
        fields = self.class.class_variable_get :@@fields
        fields.each do |field|
          value = instance_variable_get iname(field.name)
          spec[field.property] = value unless value.nil?
        end
      end
      if self.class.class_variable_defined? :@@objects
        objects = self.class.class_variable_get :@@objects
        objects.each do |object|
          v = instance_variable_get iname(object.name)
          next if v.nil?

          value = if object.array?
                    v.map(&:to_spec)
                  elsif object.map?
                    v.transform_values(&:to_spec)
                  else
                    v.to_spec
                  end
          spec[object.property] = value
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
        def self.spec(content = nil, &block)
          if content
            spec = @root.new
            spec.instance_eval content
            spec
          else
            @root.new(&block)
          end
        end
      end
    end
  end

  refine Class do
    def field(name, type = String, required: nil, property: nil)
      name, q = name.match(/^([^?]+)(\?)?$/).captures
      required = required.nil? ? !q : required
      fields = class_variable_defined?(:@@fields) ? class_variable_get(:@@fields) : class_variable_set(:@@fields, [])
      fields << FieldDesc.new(name, type, required, property)
      define_method(name) do |value = nil|
        if value.nil?
          instance_variable_get iname(name)
        else
          instance_variable_set iname(name), value
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
          if add_name == name
            define_method(add_name) do |key = nil, **named_args, &block|
              map = instance_variable_get iname(name)
              if key.nil?
                map
              else
                map ||= instance_variable_set iname(name), {}
                value = type.new(**named_args, &block)
                map[key] = value
              end
            end
          else
            define_method(name) do
              instance_variable_get iname(name)
            end
            define_method(add_name) do |key, **named_args, &block|
              map = instance_variable_get iname(name)
              map ||= instance_variable_set iname(name), {}
              value = type.new(**named_args, &block)
              map[key] = value
            end
          end
        when Array
          add_items = type.first
          types = add_items.values
          objects << ObjectDesc.new(name, types, false, array: true)
          add_items.each_pair do |add_name, type|
            define_method(name) do
              instance_variable_get iname(name)
            end
            define_method(add_name) do |**named_args, &block|
              list = instance_variable_get iname(name)
              list ||= instance_variable_set iname(name), []
              value = type.new(**named_args, &block)
              list << value
            end
          end
        else
          objects << ObjectDesc.new(name, type, false)
          define_method(name) do |**named_args, &block|
            if block.nil? && named_args.empty?
              instance_variable_get iname(name)
            else
              value = type.new(**named_args, &block)
              instance_variable_set iname(name), value
            end
          end
        end
      end
    end

    def map_shortcuts(**named_args)
      named_args.each_pair do |target, shortcuts|
        shortcuts.each_pair do |shortcut, value|
          define_method(shortcut) do |*args, **named_args, &block|
            send target, value, *args, **named_args, &block
          end
        end
      end
    end

    def block_shortcuts(**named_args)
      named_args.each_pair do |target, shortcuts|
        shortcuts.each_pair do |shortcut, block_target|
          define_method(shortcut) do |*args, **named_args, &block|
            send target do
              send block_target, *args, **named_args, &block
            end
          end
        end
      end
    end

    def object_shortcuts(**named_args)
      named_args.each_pair do |target, shortcuts|
        shortcuts.each_pair do |shortcut, values|
          define_method(shortcut) do |**named_args, &block|
            send target, **values.merge(named_args), &block
          end
        end
      end
    end

    def field_shortcuts(**named_args)
      named_args.each_pair do |target, shortcuts|
        shortcuts.each_pair do |shortcut, value|
          define_method(shortcut) do
            send target, value
          end
        end
      end
    end

    def before_field(target, &hook)
      orginal_method = instance_method(target)
      define_method(target) do |value = nil|
        if value.nil?
          orginal.bind(self).call
        else
          new_value = hook.call value
          orginal_method.bind(self).call new_value
        end
      end
    end

    def before_object(target, &hook)
      orginal_method = instance_method(target)
      define_method(target) do |*args, **named_args, &block|
        if block.nil? && named_args.empty? && args.empty?
          orginal.bind(self).call
        else
          hook.call(named_args, *args)
          orginal_method.bind(self).call(**named_args, &block)
        end
      end
    end

    def argument_names(target, *names)
      before_object(target) do |named_args, *args|
        args.each_with_index do |value, index|
          name = names[index]
          named_args[name] = value if !name.nil? && named_args[:name].nil?
        end
      end
    end
  end
end
