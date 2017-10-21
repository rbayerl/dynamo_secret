module DynamoSecret
  class Kms
    def initialize(config)
      @key_name = config[:key_name] || key_name
      @region = config.fetch(:region, region)
    end

    def create_key
      return $stdout.puts "KMS alias #{@key_name} already exists" if key
      id = client.create_key(tags: [{ tag_key: 'Owner', tag_value: user_id }]).key_metadata.key_id
      client.create_alias(alias_name: "alias/#{@key_name}", target_key_id: id)
    end

    def decrypt(data)
      client.decrypt(ciphertext_blob: data).plaintext
    rescue Aws::KMS::Errors::InvalidCiphertextException
      $stderr.puts 'Key was found but KMS decrypt failed - skipping'
      data
    end

    def encrypt(data)
      client.encrypt(key_id: key, plaintext: data).ciphertext_blob
    end

    def key
      @key ||= client.list_aliases.aliases.map do |kms_alias|
        kms_alias.target_key_id if kms_alias.alias_name == "alias/#{@key_name}"
      end.compact.first
    end

    private

    def client
      @client ||= Aws::KMS::Client.new(region: @region)
    end

    def key_name
      "dynamo_secret_#{user_id}"
    end

    def region
      ENV.fetch('AWS_REGION', 'us-west-2')
    end

    def user_id
      @user_id ||= IAM.new.user_id
    end
  end
end
