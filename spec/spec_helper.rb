require 'single_cov'
SingleCov.setup :rspec

require 'dynamo_secret'

RSpec.configure do |c|
  c.default_formatter = 'documentation'
end
