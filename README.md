# DREBS (Disaster Recovery for Elastic Block Store)

## About
* DREBS is a tool for taking periodic snapshots of EBS volumes.
* DREBS is designed to be run on the EC2 host which the EBS volumes to be snapshoted are attached so that it can be baked into AMI's.
* DREBS supports configurable retention strategies.
* DREBS supports configurable pre and post snapshot tasks such as dumping databases prior to snapshot for consistency.

## Installation & Setup
1. Clone the repo or install the gem
1. Currently configuration is located at the top of the drebs bin.  Add you ec2 key, etc.
1. Add Crontab entry: 0 * * * * drebs

## Issues
* State including config is cached in drebs_state.json.  This file will need to be deleted to get drebs to pick up new config.  Doing so will orphan current snapshots which will need to be deleted manually.

## Todo
* Tests!
* Refactor using main with db for state and external config
* Use Whenever gem for crontab setup
* Arbitrary execution intervals (Snapshots every 5 minutes instead of every hour)

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
