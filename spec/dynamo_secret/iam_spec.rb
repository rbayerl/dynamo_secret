require 'spec_helper'

SingleCov.covered!

describe DynamoSecret::IAM do
  context 'when using user credentials' do
    it 'returns a username' do
      expect_any_instance_of(Aws::IAM::CurrentUser).to receive(:user_name).and_return(
        'foo_user'
      )
      expect(described_class.new.user_id).to eq('foo_user')
    end
  end

  context 'when using root account credentials' do
    it 'returns a username' do
      expect_any_instance_of(Aws::IAM::CurrentUser).to receive(:user_name).and_return(nil)
      expect_any_instance_of(Aws::IAM::CurrentUser).to receive(:user_id).and_return(
        '1234567'
      )
      expect(described_class.new.user_id).to eq('1234567')
    end
  end
end
