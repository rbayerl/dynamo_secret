module DynamoSecret
  class Secret
    def initialize(config)
      @config = config
    end

    def delete
      resp = ask("Really delete #{site}? (y/N) ")
      return unless resp.casecmp('y')
      dynamodb.delete
      $stdout.puts "#{site} deleted"
    end

    def get(fields)
      secret = dynamodb.fetch_secret
      return decrypt(secret, fields) if secret
      $stderr.puts "Could not find record for #{site}"
      exit 1
    end

    def put
      if gpg.key.nil? && kms.key.nil?
        $stderr.puts 'Refusing to store secrets in plain text'
        exit 1
      elsif dynamodb.fetch_secret
        $stderr.puts "Site #{site} already exists"
        exit 1
      else
        secret = encrypt
        dynamodb.put_secret(secret)
      end
    end

    def setup
      dynamodb.create_table
      kms.create_key unless @config.fetch(:enable_kms, nil).nil?
    end

    def update
      secret = dynamodb.fetch_secret.merge(encrypt)
      dynamodb.put_secret(secret)
    end

    private

    def decode(data)
      data = Base64.decode64(data)
      data = kms.decrypt(data) if kms.key
      data = gpg.decrypt(data) if gpg.key
      data
    end

    def decrypt(data, fields)
      headers = [['Key', 'Value'], ['---', '-----']]
      fields ||= [['Site', data['Site']]] + data.map { |k, v| [k, decode(v)] unless k == 'Site' }.compact
      output = if fields.is_a?(Array)
                 headers + fields
               else
                 headers + data.map { |k, v| [k, decode(v)] if fields.include?(k) }.compact
               end
      widths = output.transpose.map { |x| x.map(&:length).max }.map { |w| "%-#{w}s" }.join('   ')
      output.each { |line| $stdout.puts widths % line }
    end

    def encode(data)
      data = gpg.encrypt(data) if gpg.key
      data = kms.encrypt(data) if kms.key
      Base64.encode64(data)
    end

    def dynamodb
      @dynamodb ||= DynamoDB.new(@config)
    end

    def encrypt
      encrypted_data = {
        'Site' => site
      }
      @config[:secret_data][site].each do |kv|
        kv.map { |k, v| encrypted_data[k] = encode(v) }
      end
      encrypted_data
    end

    def gpg
      @gpg ||= Gpg.new
    end

    def kms
      @kms ||= Kms.new(@config)
    end

    def site
      @config[:secret_data].map { |k, _v| k }.first
    end
  end
end
