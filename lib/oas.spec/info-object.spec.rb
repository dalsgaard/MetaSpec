require_relative '../oas'

include OAS

describe 'InfoObject' do
  context 'An empty object' do
    subject do
      InfoObject.new
    end

    it 'should have a correct spec' do
      expect(subject.to_spec).to eql({})
    end
  end

  context 'A non-empty object' do
    subject do
      InfoObject.new do
        title 'Title'
        summary 'Summary'
        description 'Description'
        terms_of_service 'Term of service'
        version '1.2.3'
        contact do
        end
        license do
        end
      end
    end

    it 'should have a correct spec' do
      expect(subject.to_spec).to eql(
        {
          'title' => 'Title',
          'summary' => 'Summary',
          'description' => 'Description',
          'termsOfService' => 'Term of service',
          'version' => '1.2.3',
          'contact' => {},
          'license' => {}
        }
      )
    end
  end
end
