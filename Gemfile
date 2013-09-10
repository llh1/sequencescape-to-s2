source "http://www.rubygems.org"
 
gemspec

gem 'lims-core', '~>2.5', :git => 'http://github.com/sanger/lims-core.git' , :branch => 'master'
gem 'lims-api', '~>2.4', :git => 'http://github.com/sanger/lims-api.git' , :branch => 'master'
gem 'lims-laboratory-app', '~>1.8', :git => 'http://github.com/sanger/lims-laboratory-app.git' , :branch => 'master'
gem 'lims-management-app', '~>1.8', :git => 'https://github.com/sanger/lims-management-app.git', :branch => 'master'
gem 'lims-busclient', '~>0.4.0', :git => 'https://github.com/sanger/lims-busclient.git', :branch => 'master'

group :development do
  gem 'mysql2', :platforms => :mri
end

group :debugger do
  gem 'debugger'
  gem 'debugger-completion'
  gem 'shotgun'
end

group :deployment do
  gem "psd_logger", :git => "http://github.com/sanger/psd_logger.git"
end
