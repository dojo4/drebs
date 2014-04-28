require "./test/helper.rb"

class TestMain < Test::Unit::TestCase

  def test_can_check_config
    TestContext.drebs_context() do |config, db, cloud, drebs|
      config_errors = drebs.class.check_config(config, config)
      assert(config_errors == [])
    end
  end

  def test_check_config_finds_missing_keys
    TestContext.drebs_context() do |config, db, cloud, drebs|
      bad_config = config.clone
      bad_config.delete(bad_config.keys.first)
      config_errors = drebs.class.check_config(config, bad_config)
      assert(config_errors.length == 1)
      assert(config_errors[0].include?("Missing key/value"))
    end
  end

  def test_can_save_strategies
    TestContext.main_context() do |config, db|
      assert(db[:strategies].all == [])
      drebs = Drebs::Main.new('config' => config, 'db' => db)
      assert(db[:strategies].all.length > 0)
    end
  end

  def test_removed_strategies_get_deactivated
    TestContext.main_context() do |config, db|
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

end
