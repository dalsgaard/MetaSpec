openapi '3.1'

info title: 'Foo'

server url: 'http://foo.bar/baz'

path '/pets', description: 'Pets' do
  post operation_id: :create_pet do
    request_body? schema: :Pet
    response CREATED, description: 'Created a pet', schema: :Pet
  end
end

path '/pets/{id}', description: 'A given pet' do
  get operation_id: :read_pet do
    parameter :id, in: :path, example: 2
    response OK, description: 'Read a given pet', schema: :Pet
  end
end

components do
  schema :Pet, type: Object do
    string :name
    integer :age?, minimum: 0, maximum: 150
    string :email, format: :email
    refs address: :Address
    array :nick_names do
      items type: String
      contains type: Number
    end
    additional_properties false
  end
  schema :Foo, type: Object do
    p :foo, enum: [1, 2, 3, 4]
    prop :bar, ref: :Bar
    examples [
      { foo: 2 },
      { foo: 4 }
    ]
  end
end
