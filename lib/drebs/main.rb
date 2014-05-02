module Drebs
  class Main
    attr_reader :config
    attr_reader :cloud
    attr_reader :db

    def initialize(params)
      unless @config = params['config'].clone()
        raise "No config_file_path passed!" 
      end
      unless @db = params['db']
        raise "No db passed!" 
      end
      update_strategies(@config.delete("strategies"))
      @cloud = Drebs::Cloud.new(@config)
      @log = Logger.new(@config["log_path"])
      @log.level = Logger::WARN
    end

    def check_cloud
      @cloud.check_cloud()
    end

    def Main.check_config(reference_config, other_config)
      reference_config = reference_config.clone()
      reference_strategy = reference_config.delete('strategies').last
  
      errors = []
      
      config_ok = reference_config.keys.each do |key|
        config_ok = other_config.has_key?(key) and other_config[key] != nil and other_config[key] != ""
        errors.push("Missing key/value for key: #{key}") unless config_ok
      end
  
      strategies = other_config['strategies']
      if strategies.is_a?(Array) and strategies.first()
        strategies.each_with_index do |strategy, i|
          strategies_ok = reference_strategy.keys.all?{|key|
            unless strategy.has_key?(key) and strategy[key] != nil and strategy[key] != ""
              errors.push("Missing key/value for key: #{key}") unless config_ok
            end
          }
        end
      else
        errors.push("Missing strategies array")
      end
  
      return errors
    end


    def update_strategies(new_strategies)
      new_strategies.each do |strategy|
        exists = @db[:strategies].filter(:config=>strategy.to_yaml).update(:status=>"active")
        if exists==0
          pre_snapshot_tasks = strategy['pre_snapshot_tasks']
          pre_snapshot_tasks = pre_snapshot_tasks ? pre_snapshot_tasks.join(",") : ""
          post_snapshot_tasks = strategy['post_snapshot_tasks']
          post_snapshot_tasks = post_snapshot_tasks ? post_snapshot_tasks.join(",") : ""
          @db[:strategies].insert(
            :config=>strategy.to_yaml,
            :snapshots=>"",
            :status=>"active",
            :time_til_next_run => strategy['hours_between'],
            :time_between_runs => strategy['hours_between'],
            :num_to_keep => strategy['num_to_keep'],
            :pre_snapshot_tasks => pre_snapshot_tasks,
            :post_snapshot_tasks => post_snapshot_tasks,
            :mount_point => strategy['mount_point']
          )
        end
      end
      deactivate_filter = new_strategies.map do |strategy|
        "(config != '#{strategy.to_yaml}' and status == 'active')"
      end.join(" and ")
      @db[:strategies].filter(deactivate_filter).update(:status => 'inactive')
    end

    def send_email(subject, body)
      host = @config['email_host']
      port = @config['email_port']
      domain = @config['email_domain']
      username = @config['email_user']
      password = @config['email_password']
      
      msg = "Subject: #{subject}\n\n#{body}"
      smtp = Net::SMTP.new(host, port)
      smtp.enable_starttls
      smtp.start(domain, username, password, :login) {|smtp|
        smtp.send_message(msg, username, @config['email_on_exception'])
      }
    end
  
    def prune_backups(strategies)
      to_prune = []

      strategies.each do |strategy|
        snapshots = strategy[:snapshots].split(",")
        if snapshots.uniq==[nil]
          @db[:strategies].filter(:config=>strategy[:config]).update(:snapshots => "")
        elsif snapshots == []
        elsif snapshots.count > strategy[:num_to_keep].to_i
          to_prune.push(snapshots.first)
        end
      end

      to_prune.each do |snapshot_to_prune|  
        snapshot = snapshot_to_prune.split(":")[0]

        begin
          @cloud.ec2.delete_snapshot(snapshot)
        rescue RightAws::AwsError => e
          type = e.errors.first.first rescue ''
          raise unless type == "InvalidSnapshot.NotFound"
        end

        remove_pruned_snapshot_from_db(snapshot_to_prune)
      end
    end

    def remove_pruned_snapshot_from_db(snapshot)
      # find the strategy to which this snapshot belongs
      strategy = @db[:strategies].all.detect{|strategy| strategy[:snapshots].split(',').include?(snapshot)}
      # update the strategy's snapshots to include all except given snapshot
      unless strategy.nil?
        new_snapshots = strategy[:snapshots].split(',').delete_if{|snap| snap == snapshot}.join(',')
        @db[:strategies].filter(:config=>strategy[:config]).update(:snapshots => new_snapshots)
      end
    end
    
    def execute
      active_strategies = @db[:strategies].filter({:status=>"active"})
  
      #Decrement time_til_next_run, save
      active_strategies.each do |s|
        @db[:strategies].filter(:config=>s[:config]).update(
          :time_til_next_run => (s[:time_til_next_run].to_i - 1)
        )
      end
  
      active_strategies = @db[:strategies].filter({:status=>"active"})

      #backup_now = strategies where time_til_next_run <= 0
      backup_now = active_strategies.to_a.select{|s| s[:time_til_next_run].to_i <= 0}
  
      #loop over strategies grouped by mount_point
      backup_now.group_by{|s| s[:mount_point]}.each do |mount_point, strategies|
        pre_snapshot_tasks = strategies.map{|s| s[:pre_snapshot_tasks].split(",")}.flatten.uniq
        post_snapshot_tasks = strategies.map{|s| s[:pre_snapshot_tasks].split(",")}.flatten.uniq
  
        @log.info("creating snapshot of #{mount_point}")
        begin
          snapshot = @cloud.create_local_snapshot(pre_snapshot_tasks, post_snapshot_tasks, mount_point)
  
          strategies.collect {|s|
            snapshots = s[:snapshots].split(",")
            snapshots.select!{|snapshot| @cloud.local_ebs_ids.include? snapshot.split(":")[1]}
            snapshots.push(
              s[:status]=='active' ?
                "#{snapshot[:aws_id]}:#{snapshot[:aws_volume_id]}" : nil
            )
            @db[:strategies].filter(:config=>s[:config]).update(
              :snapshots => snapshots.join(","),
              :time_til_next_run => s[:time_between_runs]
            )
          }
    
        rescue Exception => error
          @log.error("Exception occured during backup: #{error.message}\n#{error.backtrace.join("\n")}")
          send_email("DREBS Error!", "AWS Instance: #{@cloud.find_local_instance[:aws_instance_id]}\n#{error.message}\n#{error.backtrace.join("\n")}")
        end
      end

      prune_backups(@db[:strategies])
    end
  end
end
