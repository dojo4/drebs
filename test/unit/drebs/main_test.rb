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

        drop_table :strategies if table_exists? :strategies
        create_table :strategies do
          String :config
          String :snapshots
          String :status
          String :time_til_next_run
          String :time_between_runs
          String :num_to_keep
          String :pre_snapshot_tasks
          String :post_snapshot_tasks
        end

        drop_table :snapshots if table_exists? :snapshots
        create_table :snapshots do
          String :aws_id
          String :volume
        end 
      end

      if block
        begin
          block.call(config, main.db())
        ensure
          begin
            #fake main cleanup
            main.db() do
              drop_table :strategies if table_exists? :strategies
              drop_table :snapshots if table_exists? :snapshots
            end
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
      config_errors = drebs.class.check_config(config, config)
      assert(config_errors == [])
    end
  end

  def test_check_config_finds_missing_keys
    drebs_context() do |config, db, ec2, drebs|
      bad_config = config.clone
      bad_config.delete(bad_config.keys.first)
      config_errors = drebs.class.check_config(config, bad_config)
      assert(config_errors.length == 1)
      assert(config_errors[0].include?("Missing key/value"))
    end
  end

  def test_can_save_strategies
    main_context() do |config, db|
      assert(db[:strategies].all == [])
      drebs = Drebs::Main.new('config' => config, 'db' => db)
      assert(db[:strategies].all.length > 0)
    end
  end

  def test_removed_strategies_get_deactivated
    main_context() do |config, db|
      drebs = Drebs::Main.new('config' => config, 'db' => db)
      num_active_strategies = db[:strategies].where(:status=>"active").count
      num_inactive_strategies = db[:strategies].where(:status=>"inactive").count
      config['strategies'] = config['strategies'][1..-1]
      drebs = Drebs::Main.new('config' => config, 'db' => db)
      num_active_strategies_dec = db[:strategies].where(:status=>"active").count
      num_inactive_strategies_inc = db[:strategies].where(:status=>"inactive").count
      assert(num_active_strategies == num_active_strategies_dec + 1)
      assert(num_inactive_strategies == num_inactive_strategies_inc - 1)
    end
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
