module Drebs
  module Raid
    def get_drives_from_raid(array, file='/proc/mdstat')
      f     = File.read(file)
      disks = Array.new()

      # Here we parse the following file content from which we determine
      # the list of devices:
      #
      # Personalities : [raid10]
      # md126 : active raid10 xvdm[3] xvdl[2] xvdk[1] xvdj[0]
      #       209583104 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]
      #
      # md127 : active raid10 xvdf[3] xvdg[2] xvdi[1] xvdh[0]
      #       209583104 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]
      #
      # unused devices: <none>

      f.each_line do |line|
        if line =~ /^md\d+/
          arr = line.split()
          if arr[3] =~ /^raid\d+/
            if arr[0] == array.split('/').last
              arr[4..-1].map{|drive| drive.split('[')[0] }.each do |dsk|
                disks << dsk
              end
            end
          end
        end
      end

      return disks
    end

    extend self
  end
end
