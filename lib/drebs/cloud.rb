require 'right_aws'
require 'aws-sdk'
require 'date'
require 'net/http'
require 'logger'

module Drebs
  class Cloud
    def initialize(config)
      @config = config
      if @config['use_iam']
        @ec2 = AWS::EC2.new(
          :region => @config['region'],
          #:log_formatter => AWS::Core::LogFormatter.debug,
          #:logger => Logger.new($stdout)
        )
      else
        @ec2 = AWS::EC2.new(
          :access_key_id     => @config['aws_access_key_id'],
          :secret_access_key => @config['aws_secret_access_key'],
          :region            => @config['region']
        )
      end
    end

    def check_cloud
      find_local_instance
    end

    def find_local_instance
      inst = @ec2.instances[get_instance_id]
      return inst.exists? ? @instance ||= inst : nil
    end

    def get_instance_id
      url = URI.parse('http://169.254.169.254/latest/meta-data/instance-id')
      req = Net::HTTP::Get.new(url.to_s)
      res = Net::HTTP.start(url.host, url.port) {|http|
        http.request(req)
      }
      return res.body
    end

    def find_local_ebs(mount_point)
      return nil if not local_instance = find_local_instance
      local_instance.block_device_mappings.each_pair do |volume, obj|
        return { volume => obj }[mount_point] if volume == mount_point
      end
      return nil
    end

    def local_ebs_ids
      @ebs_ids ||= find_local_instance.block_device_mappings.map do |_, volume|
        volume.volume.id
      end rescue nil
    end

    def get_snapshot(snapshot_id)
      @ec2.snapshots.map {|a_snapshot|
        return a_snapshot if a_snapshot.id == snapshot_id
      }
      return nil
    end

    def create_local_snapshot(pre_snapshot_tasks, post_snapshot_tasks, mount_point)
      local_instance    = find_local_instance
      ip                = local_instance.ip_address
      instance_id       = local_instance.instance_id
      instance_tags     = local_instance.tags
      instance_name_tag = instance_tags.select {|i| i[0] == 'Name'}
      instance_desc     = instance_name_tag.empty? ? ip : instance_name_tag[1]
      volume_id         = local_instance.block_device_mappings[mount_point].volume.id
      timestamp         = DateTime.now.strftime("%Y%m%d%H%M%S")

      return nil if not ebs = find_local_ebs(mount_point)

      pre_snapshot_tasks.each do |task|
        result, stdout, stderr = systemu(task)
        unless result.exitstatus == 0
          raise Exception.new(
            "Error while executing pre-snapshot task: #{task} on #{instance_desc}:#{mount_point} #{instance_id}:#{volume_id} at #{timestamp}"
          )
        end
      end if pre_snapshot_tasks
      snapshot = ebs.volume.create_snapshot("DREBS #{instance_desc}:#{mount_point} #{instance_id}:#{volume_id} at #{timestamp}")
      Thread.new(snapshot.id, post_snapshot_tasks) do |snapshot_id, post_snapshot_tasks|
        1.upto(500) do |a|
          sleep(3)
          break if get_snapshot(snapshot.id).status == :completed
        end
        post_snapshot_tasks.each do |task|
          result = systemu(task)
          unless result.exitstatus == 0
            raise Exception.new(
              "Error while executing post-snapshot task: #{task} on #{instance_desc}:#{mount_point} #{instance_id}:#{volume_id} at #{timestamp}"
            )
          end
        end if post_snapshot_tasks
      end
      return snapshot
    end

    def find_local_snapshots(mount_point)
      return nil if not ebs = find_local_ebs(mount_point)
      snapshots = []
      @ec2.snapshots.each {|snapshot|
        snapshots.push(snapshot) if snapshot.volume_id == ebs.volume.id
      }
      return snapshots
    end

    def delete_snapshot(snapshot_id)
      snapshot = get_snapshot(snapshot_id)
      snapshot.delete
    end
  end
end
