require 'spec_helper'

SingleCov.covered!

describe DynamoSecret::Kms do
  context 'key does not exist' do
    it 'creates a new kms key' do
      expect_any_instance_of(described_class).to receive(:key).and_return(nil)
      expect_any_instance_of(DynamoSecret::IAM).to receive(:user_id).and_return('foobar-user')
      expect_any_instance_of(Aws::KMS::Client).to receive(:create_key).with(
        tags: [{ tag_key: 'Owner', tag_value: 'foobar-user' }]
      ).and_return(
        OpenStruct.new(
          key_metadata: OpenStruct.new(
            key_id: 'foobar-key-123'
          )
        )
      )
      expect_any_instance_of(Aws::KMS::Client).to receive(:create_alias).with(
        alias_name: 'alias/dynamo_secret_foobar-user',
        target_key_id: 'foobar-key-123'
      )
      described_class.new({}).create_key
    end
  end

  context 'key exists' do
    it 'does not create a key' do
      expect_any_instance_of(Aws::KMS::Client).to receive(:list_aliases).and_return(
        OpenStruct.new(
          aliases: [
            OpenStruct.new(
              target_key_id: 'foobar-key-123',
              alias_name: 'alias/dynamo_secret_foobar-user'
            )
          ]
        )
      )
      expect_any_instance_of(DynamoSecret::IAM).to receive(:user_id).and_return('foobar-user')
      expect_any_instance_of(IO).to receive(:puts).with(
        'KMS alias dynamo_secret_foobar-user already exists'
      )
      described_class.new({}).create_key
    end

    it 'does not decrypt with kms if not encrypted' do
      expect_any_instance_of(DynamoSecret::IAM).to receive(:user_id)
      expect_any_instance_of(Aws::KMS::Client).to receive(:decrypt).with(
        ciphertext_blob: 'do not decrypt'
      ).and_raise(Aws::KMS::Errors::InvalidCiphertextException.new(1, 2))
      expect_any_instance_of(IO).to receive(:puts).with(
        'Key was found but KMS decrypt failed - skipping'
      )
      expect(described_class.new({}).decrypt('do not decrypt')).to eq('do not decrypt')
    end

    it 'encrypts with kms' do
      expect_any_instance_of(Aws::KMS::Client).to receive(:encrypt).with(
        key_id: 'foobar-key-123',
        plaintext: 'plain text'
      ).and_return(
        OpenStruct.new(
          ciphertext_blob: 'encrypted text'
        )
      )
      expect_any_instance_of(Aws::KMS::Client).to receive(:list_aliases).and_return(
        OpenStruct.new(
          aliases: [
            OpenStruct.new(
              target_key_id: 'foobar-key-123',
              alias_name: 'alias/dynamo_secret_foobar-user'
            )
          ]
        )
      )
      expect_any_instance_of(DynamoSecret::IAM).to receive(:user_id).and_return('foobar-user')
      expect(described_class.new({}).encrypt('plain text')).to eq('encrypted text')
    end
  end
end
