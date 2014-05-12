require 'right_aws'

module Drebs
  class Cloud
    def initialize(config)
      @config = config
    end

    def check_cloud
      ec2
      find_local_instance
    end

    def ec2
      key_id = @config["aws_access_key_id"]
      key = @config["aws_secret_access_key"]
      region = @config["region"]
      return RightAws::Ec2.new(key_id, key, {:region=>region})
    end
    
    def find_local_instance
      #find a better way... right-aws?
      private_ip = UDPSocket.open{|s| s.connect("8.8.8.8", 1); s.addr.last}
      ec2.describe_instances.each do |instance|
        return instance if instance[:private_ip_address] == private_ip
      end
      return nil
    end
    
    def find_local_ebs(mount_point)
      return nil if not local_instance = find_local_instance
      local_instance[:block_device_mappings].each do |volume|
        return volume if volume[:device_name] == mount_point
      end
      return nil
    end

    def local_ebs_ids
      @ebs_ids ||= find_local_instance[:block_device_mappings].map do |volume| 
        volume[:ebs_volume_id]
      end rescue nil
    end
    
    def get_snapshot(snapshot_id)
      ec2.describe_snapshots {|a_snapshot|
        return a_snapshot if a_snapshot[:aws_id] == snapshot_id
      }
    end
    
    def create_local_snapshot(pre_snapshot_tasks, post_snapshot_tasks, mount_point)
      local_instance=find_local_instance
      ip = local_instance[:ip_address]
      instance_id = local_instance[:aws_instance_id]
      volume_id = local_instance[:block_device_mappings].select{|m| m[:device_name]==mount_point}.first[:ebs_volume_id]
      return nil if not ebs = find_local_ebs(mount_point)
      pre_snapshot_tasks.each do |task|
        result, stdout, stderr = systemu(task)
        unless result.exitstatus == 0
          raise Exception(
            "Error while executing pre-snapshot task: #{task} on #{ip}:#{mount_point} #{instance_id}:#{volume_id} "
          )
        end
      end if pre_snapshot_tasks
      snapshot = ec2.create_snapshot(ebs[:ebs_volume_id], "DREBS #{ip}:#{mount_point} #{instance_id}:#{volume_id}")
      Thread.new(snapshot[:aws_id], post_snapshot_tasks) do |snapshot_id, post_snapshot_tasks|
        1.upto(500) do |a|
          sleep(3)
          break if get_snapshot(snapshot_id)[:aws_status] == 'completed'
        end
        post_snapshot_tasks.each do |task|
          result = systemu(task)
          unless result.exitstatus == 0
            raise Exception(
              "Error while executing post-snapshot task: #{task} on #{ip}:#{mount_point} #{instance_id}:#{volume_id} "
            )
          end
        end if post_snapshot_tasks
      end
      return snapshot
    end
    
    def find_local_snapshots(mount_point)
      return nil if not ebs = find_local_ebs(mount_point)
      snapshots = []
      ec2.describe_snapshots.each {|snapshot|
        snapshots.push(snapshot) if snapshot[:aws_volume_id] == ebs[:ebs_volume_id]
      }
      return snapshots
    end
  end
end
