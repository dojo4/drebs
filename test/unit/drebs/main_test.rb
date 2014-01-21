require "main"
require "./lib/drebs/main.rb"
require "./lib/drebs/cloud.rb"
require "test/unit"
require "yaml"

class TestEC2

end

class TestMain < Test::Unit::TestCase

  EXAMPLE_CONFIG_PATH = "./config/example.yml"
  TMP_TEST_DATA_PATH = "./tmp_test_data/"

  def main_context(*args, &block)
    Main.new() do |main|
      config = YAML::load(IO.read(EXAMPLE_CONFIG_PATH))
      main.dotdir(TMP_TEST_DATA_PATH)
      main.db() do
        create_table :strategies do
          String :config
          String :snapshots
          String :status
          String :time_til_next_run
          String :time_between_runs
          String :num_to_keep
          String :pre_snapshot_tasks
          String :post_snapshot_tasks
        end unless table_exists? :strategies

        create_table :snapshots do
          String :aws_id
          String :volume
        end unless table_exists? :snapshots
      end

      if block
        begin
          block.call(config, main.db())
        ensure
          begin
            #fake main cleanup
          rescue => e
          end
        end
      end
    end
   

  end

  def cloud_context(*args, &block)
    ec2 = TestEC2.new
    main_context do |main|

      if block
        begin
          block.call(ec2)
        ensure
          begin
            #fake ec2 cleanup
          rescue => e
          end
        end
      end
    end
  end

  def drebs_context(*args, &block)
    main_context() do |config, db|
      cloud_context() do |ec2|
        drebs = Drebs::Main.new('config' => config, 'db' => db)

        if block
          begin
            block.call(config, db, ec2, drebs)
          ensure
            begin
              #fake drebs cleanup
            rescue => e
            end
          end
        end
      end
    end
  end
 
  def test_can_check_config
    drebs_context() do |config, db, ec2, drebs|
require 'pry'; binding.pry
      assert(true)
    end
  end

  def test_check_config_finds_missing_keys

  end

  def test_can_save_strategies

  end

  def test_removed_strategies_get_deactivated

  end

  def test_backups_get_pruned

  end

  def test_can_add_crontab_entry

  end

  def test_can_remove_crontab_entry

  end

  def test_can_update_crontab_entry

  end

end
