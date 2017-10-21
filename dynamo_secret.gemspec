require './lib/dynamo_secret/version'

Gem::Specification.new do |s|
  s.name        = 'dynamo_secret'
  s.version     = DynamoSecret::VERSION
  s.authors     = ['Rob Bayerl']
  s.summary     = 'Store and fetch encrypted secrets in DynamoDB'
  s.description = 'Encrypt and decrypt secrets stored in DynamoDB with GPG and/or KMS'
  s.homepage    = 'https://github.com/rbayerl/dynamo_secret'
  s.licenses    = ['MIT']
  s.files       = Dir.glob('{bin,lib}/**/*') + ['CHANGELOG.md', 'LICENSE', 'README.md']
  s.executables = ['dynamo_secret']

  s.add_runtime_dependency 'aws-sdk-dynamodb'
  s.add_runtime_dependency 'aws-sdk-iam'
  s.add_runtime_dependency 'aws-sdk-kms'
  s.add_runtime_dependency 'gpgme'
  s.add_runtime_dependency 'highline'

  s.add_development_dependency 'bump'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'single_cov'
end
