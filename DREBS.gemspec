## DREBS.gemspec
#

Gem::Specification::new do |spec|
spec.name = "DREBS"
spec.version = "0.0.1"
spec.platform = Gem::Platform::RUBY
spec.summary = "DREBS"
spec.description = "description: DREBS kicks the ass"

spec.files =
["DREBS.gemspec",
 "README.md",
 "Rakefile",
 "bin",
 "bin/drebs",
 "lib",
 "lib/drebs.rb"]

spec.executables = ["drebs"]
spec.require_path = "lib"

spec.test_files = nil


spec.add_dependency(*["right_aws", " >= 3.0.0 "])

spec.add_dependency(*["logger", " >= 1.2.8 "])

spec.add_dependency(*["main", " >= 5.0.0 "])

spec.add_dependency(*["systemu", " >= 2.4.2 "])

spec.add_dependency(*["json", " >= 1.5.1 "])


spec.extensions.push(*[])

spec.rubyforge_project = "DREBS"
spec.author = "Garett Shulman"
spec.email = "garett@dojo4.com"
spec.homepage = "https://github.com/dojo4/DREBS"
end
