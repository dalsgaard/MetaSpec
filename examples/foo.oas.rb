openapi '3.1'

info title: 'Foo'

server url: 'http://foo.bar/baz'

path '/pets/{id}', description: 'A given pet' do
  post operation_id: :post_pet do
    request_body? schema: :Pet
    parameter :id, in: :path
    parameter_ref ref: :limitParam
  end
end
