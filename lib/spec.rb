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

  class FieldOrObjectDesc
    attr_reader :name, :field_type, :object_type, :required, :property

    def initialize(name, field_type, object_type, required)
      @name = name
      @field_type = field_type
      @object_type = object_type
      @required = required
      @property = pname(name)
    end
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
      if self.class.class_variable_defined? :@@field_or_objects
        field_or_objects = self.class.class_variable_get :@@field_or_objects
        field_or_objects.each do |field_or_object|
          value = instance_variable_get iname(field_or_object.name)
          next if value.nil?

          value = value.to_spec if value.is_a? field_or_object.object_type
          spec[field_or_object.property] = value
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
    def field(name, type = String, required: nil, property: nil, array: false)
      name, q = name.match(/^([^?]+)(\?)?$/).captures
      required = required.nil? ? !q : required
      fields = class_variable_defined?(:@@fields) ? class_variable_get(:@@fields) : class_variable_set(:@@fields, [])
      fields << FieldDesc.new(name, type, required, property, array: array)
      if array
        define_method(name) do |*args|
          arr = instance_variable_get iname(name)
          if args.empty?
            arr
          else
            args.flatten!
            instance_variable_set iname(name), arr.nil? ? args : arr + args
          end
        end
      else
        define_method(name) do |value = nil|
          if value.nil?
            instance_variable_get iname(name)
          else
            instance_variable_set iname(name), value
          end
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
          if type.is_a? Array
            field(name, type.first, array: true)
          else
            field(name, type)
          end
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
          types = type.values
          objects << ObjectDesc.new(name, types, false, map: true)
          type.each_pair do |add_name, type|
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
              define_method(add_name) do |key = nil, **named_args, &block|
                map = instance_variable_get iname(name)
                if named_args.empty? && block.nil?
                  key.nil? ? map : map[key]
                else
                  map ||= instance_variable_set iname(name), {}
                  value = type.new(**named_args, &block)
                  map[key] = value
                  value
                end
              end
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

    def field_or_object(name, field_type, object_type, required: nil, property: nil)
      field_or_objects = if class_variable_defined?(:@@field_or_objects)
                           class_variable_get(:@@field_or_objects)
                         else
                           class_variable_set(:@@field_or_objects, [])
                         end
      field_or_objects << FieldOrObjectDesc.new(name, field_type, object_type, required)
      define_method(name) do |*args, **named_args, &block|
        if args.empty? && named_args.empty? && !block
          instance_variable_get iname(name)
        elsif !args.empty?
          instance_variable_set iname(name), args.first
        else
          value = object_type.new(**named_args, &block)
          instance_variable_set iname(name), value
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
          define_method(shortcut) do |*args, **named_args, &block|
            send target, *args, **values.merge(named_args), &block
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
          orginal_method.bind(self).call
        else
          new_value = instance_exec(value, &hook)
          orginal_method.bind(self).call new_value
        end
      end
    end

    def before_object(target, &hook)
      orginal_method = instance_method(target)
      define_method(target) do |*args, **named_args, &block|
        if block.nil? && named_args.empty? && args.empty?
          orginal_method.bind(self).call
        else
          new_args, new_named_args = instance_exec(args, named_args, block, &hook)
          orginal_method.bind(self).call(*new_args, **new_named_args, &block) if new_args
        end
      end
    end

    def before_map(target, &hook)
      orginal_method = instance_method(target)
      define_method(target) do |key = nil, *args, **named_args, &block|
        if block.nil? && named_args.empty? && args.empty? && key.nil?
          orginal_method.bind(self).call
        else
          new_key, new_args, new_named_args = instance_exec(key, *args, **named_args, &hook)
          orginal_method.bind(self).call(new_key, *new_args, **new_named_args, &block)
        end
      end
    end

    def before_key(target, &hook)
      before_map target do |key = nil, *args, **named_args|
        key = instance_exec(key, &hook)
        [key, args, named_args]
      end
    end

    def argument_names(**targets)
      targets.each_pair do |target, names|
        names = [names] unless names.is_a?(Array)
        before_object(target) do |args, named_args|
          new_args = []
          args.each_with_index do |value, index|
            name = names[index]
            if name.nil?
              new_args << value
            elsif named_args[:name].nil?
              named_args[name] = value
            end
          end
          [new_args, named_args]
        end
      end
    end
  end
end
