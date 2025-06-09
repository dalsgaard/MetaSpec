module Logging
  def log(message)
    puts "[LOG] #{message}"
  end
end

class DynamicMethodInvoker
  include Logging

  def initialize
    @methods = {}
  end

  def define_method(name, &block)
    @methods[name] = block
    self.class.send(:define_method, name, &block)
  end

  def invoke_method(name, *args)
    if @methods.key?(name)
      send(name, *args)
    else
      log("Method '#{name}' not defined.")
    end
  end
end

# Usage
invoker = DynamicMethodInvoker.new
invoker.define_method(:greet) { |name| "Hello, #{name}!" }
invoker.define_method(:farewell) { |name| "Goodbye, #{name}." }

puts invoker.invoke_method(:greet, 'Alice')
puts invoker.invoke_method(:farewell, 'Bob')
puts invoker.invoke_method(:unknown_method)
