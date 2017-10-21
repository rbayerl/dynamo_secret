require 'spec_helper'

SingleCov.covered!

describe DynamoSecret::CLI do
  context 'works without optional arguments' do
    def ask_site
      expect_any_instance_of(HighLine).to receive(:ask).with('Site: ')
    end

    it 'creates dynamodb table' do
      expect_any_instance_of(DynamoSecret::Secret).to receive(:setup)
      described_class.new(['-i']).run
    end

    it 'asks for site and gets secrets' do
      expect_any_instance_of(DynamoSecret::Secret).to receive(:get).with(nil)
      ask_site
      described_class.new(['-g']).run
    end

    it 'asks for site, keys, and values to store' do
      expect_any_instance_of(DynamoSecret::Secret).to receive(:put)
      ask_site
      expect_any_instance_of(HighLine).to receive(:ask).with('Key [ENTER to quit]: ').and_return('foo')
      expect_any_instance_of(HighLine).to receive(:ask).with('Key [ENTER to quit]: ').and_return('')
      expect_any_instance_of(HighLine).to receive(:ask).with('Value for foo: ').and_return('')
      described_class.new(['-a']).run
    end

    it 'asks for site, keys, and values to update' do
      expect_any_instance_of(DynamoSecret::Secret).to receive(:update)
      ask_site
      expect_any_instance_of(described_class).to receive(:ask_key_pairs).with(nil, nil)
      described_class.new(['-u']).run
    end

    it 'asks for site to delete' do
      expect_any_instance_of(DynamoSecret::Secret).to receive(:delete)
      ask_site
      described_class.new(['-d']).run
    end

    it 'lists secrets' do
      expect_any_instance_of(DynamoSecret::IAM).to receive(:user_id)
      expect_any_instance_of(DynamoSecret::DynamoDB).to receive(:list_secrets)
      described_class.new(['-l']).run
    end
  end

  context 'works with optional arguments' do
    it 'does not ask for site, keys, or values' do
      expect_any_instance_of(DynamoSecret::Secret).to receive(:put)
      described_class.new(['-a', 'foo', 'bar', '1']).run
    end
  end

  context 'handles errors' do
    it 'prints usage and exits when no options are supplied' do
      expect_any_instance_of(IO).to receive(:puts)
      expect_any_instance_of(Kernel).to receive(:exit).with(1)
      described_class.new([]).run
    end

    it 'prints usage when too many arguments are supplied' do
      expect_any_instance_of(IO).to receive(:puts)
      expect_any_instance_of(Kernel).to receive(:exit).with(1)
      expect_any_instance_of(DynamoSecret::Secret).to receive(:put)
      described_class.new(['-a', 1, 2, 3, 4]).run
    end
  end
end
