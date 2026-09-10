source 'https://rubygems.org'

gemspec

gem 'rake'

gem 'roo'
gem 'csv'
gem 'bigdecimal'

gem 'simplecov', require: false
gem 'minitest'
gem 'minitest-reporters'
gem 'activesupport' # write_value's percent and hh:mm:ss branches use its core extensions (see test/test_helper.rb).

group :benchmarks do
  gem 'caxlsx', git: 'https://github.com/caxlsx/caxlsx'
  gem 'write_xlsx'
  gem 'xlsxtream'
  gem 'benchmark-ips'
  gem 'process_memory', git: 'https://github.com/paxa/process_memory', platforms: :ruby
end
