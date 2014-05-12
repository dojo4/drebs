require "main"
require "./lib/drebs/main.rb"
require "./lib/drebs/cloud.rb"
require "test/unit"
require "yaml"

EXAMPLE_CONFIG_PATH = "./config/example.yml"
TMP_TEST_DATA_PATH = "./tmp_test_data/"

class TestEC2
  def initialize(*args)
    @snapshots = []
    @instances = [
      {
        private_ip_address: UDPSocket.open{|s| s.connect("8.8.8.8", 1); s.addr.last},
        ip_address: "127.0.0.1",
        aws_instance_id: "fake_instance",
        block_device_mappings: [
          {device_name: "/dev/sda1", ebs_volume_id: "fake_sda1"},
          {device_name: "/dev/sdh", ebs_volume_id: "fake_sdh"}
        ]
      }
    ]
  end

  def describe_snapshots()
    @snapshots
  end

  def describe_instances()
    @instances
  end

  def create_snapshot(ebs_volume_id, snapshot_name)
    new_snapshot = {
      aws_id: "fake_snap-"+rand(36**6).to_s(36),
      aws_status: 'completed',
      aws_volume_id: ebs_volume_id
    }
    @snapshots.push(new_snapshot)
    new_snapshot
  end
end

class TestCloud < Drebs::Cloud
  def ec2; @ec2 ||= TestEC2.new; end
end

class TestContext
  def TestContext.main_context(&block)
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

  def TestContext.cloud_context(config, &block)
    cloud = TestCloud.new(config)
    main_context do |main|
      if block
        begin
          block.call(cloud)
        ensure
          begin
            #fake cloud cleanup
          rescue => e
          end
        end
      end
    end
  end

  def TestContext.drebs_context(&block)
    main_context() do |config, db|
      cloud_context(config) do |cloud|
        drebs = Drebs::Main.new('config' => config, 'db' => db)

        if block
          begin
            block.call(config, db, cloud, drebs)
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
end
