# DREBS (Disaster Recovery for Elastic Block Store)

## About
* DREBS is a tool for taking periodic snapshots of EBS volumes.
* DREBS is designed to be run on the EC2 host which the EBS volumes to be snapshoted are attached so that it can be baked into AMI's.
* DREBS supports configurable retention strategies.
* DREBS supports configurable pre and post snapshot tasks such as dumping databases prior to snapshot for consistency.
* DREBS is currently implented to be run every hour but will soon support arbitrary intervals

## Installation & Setup
1. Clone the repo or install the gem
1. Output the example configuration to a file: drebs check_config example_config > your_config.yml
1. Create an AWS account with authorization limited to create, list, & delete snapshots (Example comming soon)
1. Add AWS API keys for above account to your_config.yml
1. configure your_config.yml per your backup requirements
1. test your configuration: drebs check_config your_config.yml && drebs check_cloud your_config.yml
1. Add Crontab entry: 0 * * * * drebs execute your_config.yml

## Todo
* Improve test coverage
* Use Whenever gem for crontab setup
* Arbitrary execution intervals (Snapshots every 5 minutes instead of every hour)
* AWS API keys and other config values from Instance Data: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AESDG-chapter-instancedata.html
* Add example AWS user access configuration
* Implement support for pruning to occur from some other host so that the keys to delete snapshots are not available on host.

## Copyright 2014 Garett Shulman

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
