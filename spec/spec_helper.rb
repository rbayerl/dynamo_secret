require 'single_cov'
SingleCov.setup :rspec

RSpec.configure do |c|
  c.default_formatter = 'documentation'
end
