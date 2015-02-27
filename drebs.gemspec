## drebs.gemspec
#

require './lib/drebs/version.rb'

Gem::Specification::new do |spec|
spec.name = 'drebs'
spec.version = Drebs::VERSION
spec.platform = Gem::Platform::RUBY
spec.summary = "drebs"
spec.description = "drebs: Disaster Recovery for Elastic Block Store. An AWS EBS backup script."

spec.files =
["README.md",
 "Rakefile",
 "bin",
 "bin/drebs",
 "config",
 "config/example.yml",
 "drebs.gemspec",
 "lib",
 "lib/drebs",
 "lib/drebs.rb",
 "lib/drebs/cloud.rb",
 "lib/drebs/main.rb",
 "lib/drebs/raid.rb",
 "lib/drebs/version.rb",
 "test",
 "test/helper.rb",
 "test/unit",
 "test/unit/drebs",
 "test/unit/drebs/drebs_test.rb",
 "test/unit/drebs/main_test.rb",
 #"tmp_test_data",
 #"tmp_test_data/db.sqlite"
 ]

spec.executables = ["drebs"]
spec.require_path = "lib"

spec.test_files = nil


spec.add_dependency(*["aws-sdk-1", ">= 1.57.0"])

spec.add_dependency(*["logger", ">= 1.2.8"])

spec.add_dependency(*["main", ">= 5.2.0"])

spec.add_dependency(*["systemu", ">= 2.4.2"])

spec.add_dependency(*["json", ">= 1.5.1"])

spec.add_dependency(*["pry", ">= 0.9.12.6"])

spec.add_dependency(*["sequel", ">=4.19.0"])

spec.add_dependency(*["amalgalite", ">=1.4.0"])


spec.extensions.push(*[])

spec.rubyforge_project = "DREBS"
spec.authors = ["Garett Shulman", "Miles Matthias"]
spec.email = "miles@dojo4.com"
spec.homepage = "https://github.com/dojo4/drebs"
spec.licenses = "Apache-2.0"
end
