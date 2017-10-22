require 'highline/import'
require 'optparse'
require 'yaml'
require 'dynamo_secret/dynamodb'
require 'dynamo_secret/secret'
require 'dynamo_secret/version'

module DynamoSecret
  class CLI
    def initialize(args)
      @args = args
    end

    def run
      load_config
      parse_args(@args)
      perform_action
    end

    private

    def ask_key_pairs(keys, values)
      keys = keys.to_s.split(',')
      values = values.to_s.split(',')
      if keys.empty?
        loop do
          key = ask('Key [ENTER to quit]: ')
          break if key == ''
          keys << key
        end
      end
      keys.map.with_index do |key, index|
        { key => values[index].nil? || values[index] == '-' ? ask("Value for #{key}: ") : values[index] }
      end
    end

    def ask_secret_data
      if @args.count > 3
        $stderr.puts usage
        exit 1
      else
        @config[:secret_data][site] = ask_key_pairs(@args.shift, @args.shift)
      end
    end

    def load_config
      config_file = "#{ENV['HOME']}/.dynamo_secret.yml"
      @config = File.exist?(config_file) ? YAML.load_file(config_file) : {}
      @config[:secret_data] = {}
    end

    def parse_args(args)
      OptionParser.new do |opts|
        opts.banner = usage
        opts.version = VERSION
        opts.on('-l', '--list', 'List all sites stored in table') { |_l| @action = 'list' }
        opts.on('-i', '--init', 'Set up DynamoDB and KMS') { |_i| @action = 'init' }
        opts.on('-g', '--get', 'Get a secret') { |_g| @action = 'get' }
        opts.on('-a', '--add', 'Add a new secret') { |_a| @action = 'put' }
        opts.on('-u', '--update', 'Update an existing secret') { |_u| @action = 'update' }
        opts.on('-d', '--delete', 'Remove site from table') { |_d| @action = 'delete' }
        opts.on('-k', '--kms', 'Enable KMS key creation (init only)') { |k| @config[:enable_kms] = k }
      end.parse!(args)
      @args = args
    end

    def perform_action
      case @action
      when 'init'
        Secret.new(@config).setup
      when 'get'
        @config[:secret_data][site] = []
        Secret.new(@config).get(@args.shift)
      when 'put'
        ask_secret_data
        Secret.new(@config).put
      when 'update'
        ask_secret_data
        Secret.new(@config).update
      when 'delete'
        @config[:secret_data][site] = []
        Secret.new(@config).delete
      when 'list'
        DynamoDB.new(@config).list_secrets
      else
        $stderr.puts usage
        exit 1
      end
    end

    def site
      @site ||= @args.any? ? @args.shift : ask('Site: ')
    end

    def usage
      'Usage:
dynamo_secret -l|--list
dynamo_secret -i|--init   [-k|--kms]
dynamo_secret -g|--get    [site] [key1,key2,...]
dynamo_secret -a|--add    [site] [key1,key2,...] [val1,val2,...]
dynamo_secret -u|--update [site] [key1,key2,...] [val1,val2,...]
dynamo_secret -d|--delete [site]'
    end
  end
end
