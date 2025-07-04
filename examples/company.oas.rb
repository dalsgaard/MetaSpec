openapi '3.1.0'

info title: 'Company API', version: '0.1.0'

server url: 'http://127.0.0.1:8000'

path '/companies', desc: 'Companies' do
  post oid: :createCompany, desc: 'Create new company' do
    request_body schema: :CompanyData
    response CREATED, desc: 'Created a company', schema: :Company
    response UNSUPPORTED_MEDIA_TYPE, desc: 'Request body is not JSON'
    response BAD_REQUEST, desc: 'Invalid request body'
  end

  get oid: :listCompanies, desc: 'List all companies' do
    parameter :q, in: :query
    response OK, schema: [:Company], desc: 'List of all companies'
    response NOT_ACCEPTABLE, desc: 'Client can not accept JSON'
  end
end

path '/companies/{companyId}', desc: 'A given company' do
  parameter :companyId, in: :path, desc: 'Company ID', example: '2'

  get oid: :showCompany, desc: 'Show details about a company' do
    response OK, desc: 'Details about a company', schema: :Company
    response NOT_ACCEPTABLE, desc: 'Client can not accept JSON'
    response NOT_FOUND, desc: 'Company could not be found'
  end

  put oid: :updateCompany, desc: 'Update a company' do
    request_body schema: :CompanyData
    response OK, desc: 'Updated the company', schema: :Company
    response UNSUPPORTED_MEDIA_TYPE, desc: 'Request body is not JSON'
    response NOT_FOUND, desc: 'Company could not be found'
    response BAD_REQUEST, desc: 'Invalid request body'
  end
end

path '/companies/{companyId}/owners', desc: 'Owners of a given company' do
  parameter :companyId, in: :path, desc: 'Company ID', example: '2'

  post oid: :addOwner, desc: 'Add a new owner to a given company' do
    request_body schema: :OwnerData
    response CREATED, desc: 'Added an owner', schema: :Owner
    response UNSUPPORTED_MEDIA_TYPE, desc: 'Request body is not JSON'
    response NOT_FOUND, desc: 'Company could not be found'
    response BAD_REQUEST, desc: 'Invalid request body'
    response UNAUTHORIZED, desc: 'Missing permissions'
  end
end

path '/companies/{companyId}/owners/{ownerId}', desc: 'A given Owner of a given company' do
  parameter :companyId, in: :path, desc: 'Company ID', example: '2'
  parameter :ownerId, in: :path, desc: 'Owner ID', example: '1'

  put oid: :updateOwner, desc: 'Update a owner of a given company' do
    request_body schema: :OwnerData
    response OK, desc: 'Updated an owner', schema: :Owner
    response UNSUPPORTED_MEDIA_TYPE, desc: 'Request body is not JSON'
    response NOT_FOUND, desc: 'Company or Owner could not be found'
    response BAD_REQUEST, desc: 'Invalid request body'
  end
end

components do
  schema :CompanyData, type: Object do
    string :name
    string :country
    string :phone?
    examples [
      {
        name: 'Foo A/S',
        country: 'Denmark',
        phone: '+4512345678'
      },
      {
        name: 'Bar A/S',
        country: 'Denmark',
        phone: '+4523456789'
      },
      {
        name: 'Baz A/S',
        country: 'Denmark'
      }
    ]
  end

  schema :Company, type: Object do
    string :id
    array :owners do
      items ref: :OwnerData
    end
    all_of ref: :CompanyData
  end

  schema :OwnerData, type: Object do
    string :name
    string :ssn
    examples [
      {
        name: 'Kim Dalsgaard',
        ssn: '1234567890'
      },
      {
        name: 'John Doe',
        ssn: '3456789099'
      }
    ]
  end

  schema :Owner, type: Object do
    string :id
    all_of ref: :OwnerData
  end

  security_scheme 'bearerAuth' do
    type :http
    scheme :bearer
    bearer_format :JWT
  end
end

security requirement: 'bearerAuth'
