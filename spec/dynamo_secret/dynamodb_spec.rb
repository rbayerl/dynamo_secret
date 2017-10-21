require 'spec_helper'

SingleCov.covered!

describe DynamoSecret::DynamoDB do
  context 'works with custom configuration' do
    it 'honors custom region and table name' do
      expect(Aws::DynamoDB::Client).to receive(:new).with(region: 'custom-region').and_return(Aws::DynamoDB::Client)
      expect(Aws::DynamoDB::Client).to receive(:create_table).with(
        attribute_definitions: [{ attribute_name: 'Site', attribute_type: 'S' }],
        table_name: 'custom-table',
        key_schema: [{ attribute_name: 'Site', key_type: 'HASH' }],
        provisioned_throughput: {
          read_capacity_units: 25,
          write_capacity_units: 25
        }
      )
      expect_any_instance_of(IO).to receive(:puts).with('Created new table: custom-table')
      described_class.new(table_name: 'custom-table', region: 'custom-region').create_table
    end
  end

  context 'works with default configuration' do
    it 'creates a new table' do
      expect(Aws::DynamoDB::Client).to receive(:new).with(region: 'us-west-2').and_return(Aws::DynamoDB::Client)
      expect_any_instance_of(DynamoSecret::IAM).to receive(:user_id).and_return('foo-user')
      expect(Aws::DynamoDB::Client).to receive(:create_table).with(
        attribute_definitions: [{ attribute_name: 'Site', attribute_type: 'S' }],
        table_name: 'dynamo_secret_foo-user',
        key_schema: [{ attribute_name: 'Site', key_type: 'HASH' }],
        provisioned_throughput: {
          read_capacity_units: 25,
          write_capacity_units: 25
        }
      )
      expect_any_instance_of(IO).to receive(:puts).with('Created new table: dynamo_secret_foo-user')
      described_class.new({}).create_table
    end

    it 'deletes a site' do
      expect_any_instance_of(DynamoSecret::IAM).to receive(:user_id).and_return('foo-user')
      expect_any_instance_of(Aws::DynamoDB::Client).to receive(:delete_item).with(
        key: {
          'Site' => 'foobar'
        },
        table_name: 'dynamo_secret_foo-user'
      )
      described_class.new(secret_data: { 'foobar' => { 'foo' => 'bar' } }).delete
    end

    it 'fetches a site' do
      expect_any_instance_of(DynamoSecret::IAM).to receive(:user_id).and_return('foo-user')
      expect_any_instance_of(Aws::DynamoDB::Client).to receive(:get_item).with(
        key: {
          'Site' => 'foobar'
        },
        table_name: 'dynamo_secret_foo-user'
      ).and_return(OpenStruct.new(item: 'foo'))
      described_class.new(secret_data: { 'foobar' => { 'foo' => 'bar' } }).fetch_secret
    end

    it 'lists sites' do
      expect_any_instance_of(DynamoSecret::IAM).to receive(:user_id).and_return('foo-user')
      expect_any_instance_of(Aws::DynamoDB::Client).to receive(:scan).with(
        table_name: 'dynamo_secret_foo-user'
      ).and_return(OpenStruct.new(items: [{ 'Site' => 'foobar' }]))
      expect_any_instance_of(IO).to receive(:puts).with('foobar')
      described_class.new({}).list_secrets
    end

    it 'adds secrets' do
      expect_any_instance_of(DynamoSecret::IAM).to receive(:user_id).and_return('foo-user')
      expect_any_instance_of(Aws::DynamoDB::Client).to receive(:put_item).with(
        item: 'foobar_item',
        table_name: 'dynamo_secret_foo-user'
      )
      described_class.new({}).put_secret('foobar_item')
    end
  end

  context 'handles errors' do
    it 'warns when the table already exists' do
      expect_any_instance_of(DynamoSecret::IAM).to receive(:user_id).and_return('foo-user')
      expect_any_instance_of(Aws::DynamoDB::Client).to receive(:create_table).with(
        attribute_definitions: [{ attribute_name: 'Site', attribute_type: 'S' }],
        table_name: 'dynamo_secret_foo-user',
        key_schema: [{ attribute_name: 'Site', key_type: 'HASH' }],
        provisioned_throughput: {
          read_capacity_units: 25,
          write_capacity_units: 25
        }
      ).and_raise(Aws::DynamoDB::Errors::ResourceInUseException.new(1, 2))
      expect_any_instance_of(IO).to receive(:puts).with('Table dynamo_secret_foo-user already exists')
      described_class.new({}).create_table
    end

    it 'exits if table does not exist' do
      expect_any_instance_of(DynamoSecret::IAM).to receive(:user_id).and_return('foo-user')
      expect_any_instance_of(Aws::DynamoDB::Client).to receive(:get_item).with(
        key: {
          'Site' => 'foobar'
        },
        table_name: 'dynamo_secret_foo-user'
      ).and_raise(Aws::DynamoDB::Errors::ResourceNotFoundException.new(1, 2))
      expect_any_instance_of(IO).to receive(:puts).with('Table dynamo_secret_foo-user not found')
      expect_any_instance_of(Kernel).to receive(:exit).with(1)
      described_class.new(secret_data: { 'foobar' => { 'foo' => 'bar' } }).fetch_secret
    end
  end
end
