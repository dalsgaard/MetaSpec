openapi '3.1'

info title: 'Foo'

server url: 'http://foo.bar/baz'

path '/pets/{id}', description: 'A given pet' do
  post operation_id: :post_pet do
    request_body? schema: :Pet
    parameter :id, in: :path
    parameter_ref :limitParam
    response OK, description: 'OK'
    response_ref CREATED, :petCreated
  end
end

components do
  schema :Pet, type: Object do
    string :name
    integer :age?
    array :arr? do
      items type: Number
    end
    array :status do
      prefix_item type: Number
      prefix_item type: String
    end
  end
  schema :Foo, type: Object do
    all_of type: Object
  end
end
