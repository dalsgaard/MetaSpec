def rubyfied_name(name)
  name.to_s.delete_prefix('$').gsub(/([A-Z])/) { "_#{Regexp.last_match(1).downcase}" }
end

class Class
  def fields(*fields)
    fields.each do |name|
      attr_reader rubyfied_name(name)
    end
    @fields ||= []
    @fields += fields
  end

  def objects(**objects)
    objects.keys.each do |name|
      attr_reader rubyfied_name(name)
    end
    @objects ||= []
    @objects += objects.entries
  end

  def maps(**maps)
    maps.keys.each do |name|
      attr_reader rubyfied_name(name)
    end
    @maps ||= []
    @maps += maps.entries
  end
end

module SpecDom
  class DomObject
    def initialize(data)
      self.class.fields.each do |name|
        value = data[name.to_s]
        instance_variable_set "@#{rubyfied_name(name)}", value unless value.nil?
      end
      self.class.objects.each do |name, type|
        d = data[name.to_s]
        next if d.nil?

        case type
        when Array
          type = type.first
          value = d.map do |i|
            type.is_a?(Hash) ? resolve_type(type, i).new(i) : type.new(i)
          end
        when Hash
          type = resolve_type(type, d)
          value = type.new d
        else
          value = type.new d
        end
        instance_variable_set "@#{rubyfied_name(name)}", value
      end
      self.class.maps.each do |name, type|
        d = data[name.to_s]
        next if d.nil?

        value = d.transform_values do |v|
          type.is_a?(Hash) ? resolve_type(type, v).new(v) : type.new(v)
        end
        instance_variable_set "@#{rubyfied_name(name)}", value
      end
    end

    private

    def resolve_type(types, _data)
      types[nil]
    end
  end
end
