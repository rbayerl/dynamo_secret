require 'aws-sdk-dynamodb'
require 'gpgme'
require 'dynamo_secret/iam'

module DynamoSecret
  class DynamoDB
    def initialize(config)
      @table_name = config[:table_name] || table_name
      @region = config.fetch(:region, region)
      @secret_data = config.fetch(:secret_data, {})
    end

    def create_table
      client.create_table(
        attribute_definitions: [{ attribute_name: 'Site', attribute_type: 'S' }],
        table_name: @table_name,
        key_schema: [{ attribute_name: 'Site', key_type: 'HASH' }],
        provisioned_throughput: {
          read_capacity_units: 25,
          write_capacity_units: 25
        }
      )
      $stdout.puts "Created new table: #{@table_name}"
    rescue Aws::DynamoDB::Errors::ResourceInUseException
      $stderr.puts "Table #{@table_name} already exists"
    end

    def delete
      client.delete_item(
        key: {
          'Site' => @secret_data.map { |k, _v| k }.first
        },
        table_name: @table_name
      )
    end

    def fetch_secret
      client.get_item(
        key: {
          'Site' => @secret_data.map { |k, _v| k }.first
        },
        table_name: @table_name
      ).item
    rescue Aws::DynamoDB::Errors::ResourceNotFoundException
      $stderr.puts "Table #{@table_name} not found"
      exit 1
    end

    def list_secrets
      client.scan(table_name: @table_name).items.each { |item| $stdout.puts item['Site'] }
    end

    def put_secret(secret_data)
      client.put_item(
        item: secret_data,
        table_name: @table_name
      )
    end

    private

    def client
      @client ||= Aws::DynamoDB::Client.new(region: @region)
    end

    def region
      ENV.fetch('AWS_REGION', 'us-west-2')
    end

    def table_name
      "dynamo_secret_#{IAM.new.user_id}"
    end
  end
end
