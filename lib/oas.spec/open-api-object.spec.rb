require_relative '../oas'

include OAS

describe 'OpenAPIObject' do
  context 'An empty object' do
    subject do
      OpenAPIObject.new
    end

    it 'should have a correct spec' do
      expect(subject.to_spec).to eql({})
    end
  end

  context 'A non-empty object' do
    subject do
      OpenAPIObject.new do
        openapi '3.1'
        info do
        end
        server do
        end
      end
    end

    it 'should have a correct spec' do
      expect(subject.to_spec).to eql(
        {
          'openapi' => '3.1',
          'info' => {},
          'servers' => [{}]
        }
      )
    end
  end
end
