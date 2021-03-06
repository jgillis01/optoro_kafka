#<
# Install and configure ZFS on EBS
#>

include_recipe 'optoro_zfs'

# Creating kafka user for ZFS partition
group node['kafka']['group'] do
  action :create
end

user node['kafka']['user'] do
  comment 'Kafka user'
  uid node['kafka']['uid'] if node['kafka']['uid']
  gid node['kafka']['group']
  shell '/bin/bash'
  home "/home/#{node['kafka']['user']}"
  supports :manage_home => true
end

node['optoro_kafka']['disks'].each_with_index do |disk, index|
  aws_ebs_volume "kafka-#{index}" do
    size node['optoro_kafka']['disk_size']
    device disk
    action [:create, :attach]
  end
end

# make our disk names compatible with what ubuntu sees.
# e.g. /dev/sdf will become /dev/xvdf
virtual_disks = node['optoro_kafka']['disks'].map { |disk| disk.sub('/dev/s', '/dev/xv') }

zpool 'kafka' do
  disks virtual_disks
  force true
end

zfs 'kafka' do
  mountpoint node['kafka']['server.properties']['log.dirs']
  atime 'off'
  compression 'lz4'
end

directory node['kafka']['server.properties']['log.dirs'] do
  owner 'kafka'
  group 'kafka'
end
