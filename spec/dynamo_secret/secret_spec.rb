require 'spec_helper'

SingleCov.covered!

describe DynamoSecret::Secret do
  let(:config) { { key_name: 'foobar-key', table_name: 'foobar-table' } }

  context 'deleting sites' do
    it 'deletes the site with a lowercase y' do
      expect_any_instance_of(HighLine).to receive(:ask).with('Really delete foobar? (y/N) ').and_return('y')
      expect_any_instance_of(DynamoSecret::DynamoDB).to receive(:delete)
      expect_any_instance_of(IO).to receive(:puts).with('foobar deleted')
      described_class.new(config.merge(secret_data: { 'foobar' => nil })).delete
    end

    it 'deletes the site with an uppercase Y' do
      expect_any_instance_of(HighLine).to receive(:ask).with('Really delete foobar? (y/N) ').and_return('Y')
      expect_any_instance_of(DynamoSecret::DynamoDB).to receive(:delete)
      expect_any_instance_of(IO).to receive(:puts).with('foobar deleted')
      described_class.new(config.merge(secret_data: { 'foobar' => nil })).delete
    end
  end

  context 'getting secrets' do
    it 'fetches all fields' do
      expect_any_instance_of(DynamoSecret::DynamoDB).to receive(:fetch_secret).and_return(
        'Site' => 'foobar',
        'secret' => 'wom'
      )
      expect(Base64).to receive(:decode64).with('wom').and_return('wom2')
      expect_any_instance_of(DynamoSecret::Kms).to receive(:key).and_return('123-456-789')
      expect_any_instance_of(DynamoSecret::Kms).to receive(:decrypt).with('wom2').and_return('wom3')
      expect_any_instance_of(DynamoSecret::Gpg).to receive(:key).and_return(true)
      expect_any_instance_of(DynamoSecret::Gpg).to receive(:decrypt).with('wom3').and_return('wom_final')
      expect_any_instance_of(IO).to receive(:puts).with('Key      Value    ')
      expect_any_instance_of(IO).to receive(:puts).with('---      -----    ')
      expect_any_instance_of(IO).to receive(:puts).with('Site     foobar   ')
      expect_any_instance_of(IO).to receive(:puts).with('secret   wom_final')
      expect(described_class.new(config).get(nil)).to eq(
        [['Key', 'Value'], ['---', '-----'], ['Site', 'foobar'], ['secret', 'wom_final']]
      )
    end

    it 'fetches only specified fields' do
      expect_any_instance_of(DynamoSecret::DynamoDB).to receive(:fetch_secret).and_return(
        'Site' => 'foobar',
        'secret' => 'wom'
      )
      expect(Base64).to receive(:decode64).with('wom').and_return('wom2')
      expect_any_instance_of(DynamoSecret::Kms).to receive(:key).and_return(true)
      expect_any_instance_of(DynamoSecret::Kms).to receive(:decrypt).with('wom2').and_return('wom3')
      expect_any_instance_of(DynamoSecret::Gpg).to receive(:key).and_return(true)
      expect_any_instance_of(DynamoSecret::Gpg).to receive(:decrypt).with('wom3').and_return('wom_final')
      expect_any_instance_of(IO).to receive(:puts).with('Key      Value    ')
      expect_any_instance_of(IO).to receive(:puts).with('---      -----    ')
      expect_any_instance_of(IO).to receive(:puts).with('secret   wom_final')
      expect(described_class.new(config).get('secret')).to eq(
        [['Key', 'Value'], ['---', '-----'], ['secret', 'wom_final']]
      )
    end

    it 'prints an error with empty results' do
      expect_any_instance_of(DynamoSecret::DynamoDB).to receive(:fetch_secret).and_return(nil)
      expect_any_instance_of(IO).to receive(:puts).with('Could not find record for foo')
      expect_any_instance_of(Kernel).to receive(:exit).with(1)
      described_class.new(config.merge(secret_data: { 'foo' => nil })).get('secret')
    end
  end

  context 'storing secrets' do
    it 'fails if secret already exists' do
      expect_any_instance_of(DynamoSecret::Gpg).to receive(:key).and_return(true)
      expect_any_instance_of(DynamoSecret::DynamoDB).to receive(:fetch_secret).and_return(1)
      expect_any_instance_of(IO).to receive(:puts).with('Site foo already exists')
      expect_any_instance_of(Kernel).to receive(:exit).with(1)
      described_class.new(config.merge(secret_data: { 'foo' => nil })).put
    end

    it 'stores secrets' do
      expect_any_instance_of(DynamoSecret::DynamoDB).to receive(:fetch_secret).and_return(nil)
      expect_any_instance_of(DynamoSecret::Gpg).to receive(:key).twice.and_return(true)
      expect_any_instance_of(DynamoSecret::Gpg).to receive(:encrypt).with('wom').and_return('wom2')
      expect_any_instance_of(DynamoSecret::Kms).to receive(:key).and_return(true)
      expect_any_instance_of(DynamoSecret::Kms).to receive(:encrypt).with('wom2').and_return('wom3')
      expect(Base64).to receive(:encode64).with('wom3').and_return('wom_final')
      expect_any_instance_of(DynamoSecret::DynamoDB).to receive(:put_secret).with(
        'Site' => 'foo',
        'secret' => 'wom_final'
      )
      described_class.new(config.merge(secret_data: { 'foo' => [{ 'secret' => 'wom' }] })).put
    end

    it 'exits if no keys exist' do
      expect_any_instance_of(DynamoSecret::Gpg).to receive(:key).and_return(nil)
      expect_any_instance_of(DynamoSecret::Kms).to receive(:key).and_return(nil)
      expect_any_instance_of(IO).to receive(:puts).with('Refusing to store secrets in plain text')
      expect_any_instance_of(Kernel).to receive(:exit).with(1)
      described_class.new(config.merge(secret_data: { 'foo' => [{ 'secret' => 'wom' }] })).put
    end
  end

  context 'it creates a table and kms key' do
    it 'creates kms and dynamodb' do
      expect_any_instance_of(DynamoSecret::DynamoDB).to receive(:create_table)
      expect_any_instance_of(DynamoSecret::Kms).to receive(:create_key)
      described_class.new(config.merge(enable_kms: true)).setup
    end
  end

  context 'allows secrets to be updated' do
    it 'replaces secret values' do
      expect_any_instance_of(DynamoSecret::DynamoDB).to receive(:fetch_secret).and_return(
        'Site' => 'foo',
        'secret' => 'wombat'
      )
      expect_any_instance_of(described_class).to receive(:encrypt).and_return('secret' => 'bar')
      expect_any_instance_of(DynamoSecret::DynamoDB).to receive(:put_secret).with(
        'Site' => 'foo',
        'secret' => 'bar'
      )
      described_class.new(config).update
    end
  end
end
