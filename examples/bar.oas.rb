openapi '3.1.0'

info title: 'Bar', version: '1.0.0'

path '/hello', description: 'Hello' do
  get do
    response OK, desc: 'Hello' do
      schema [String]
    end
  end
end

security requirement: 'bearerAuth'

components do
  security_scheme 'bearerAuth' do
    type :http
    scheme :bearer
    bearer_format :JWT
  end
end
