
def discover_java_net_properties_location
  updatedb_command = Mixlib::ShellOut.new('updatedb')
  updatedb_command.run_command
  updatedb_command.error!

  locate_command = Mixlib::ShellOut.new('locate /jre/lib/net.properties')
  locate_command.run_command
  locate_command.error!
  locate_command.stdout
end

def discover_java_location
  puts "SELF: #{self.class}"
  net_properties_location = discover_java_net_properties_location
  if net_properties_location.length == 0
    raise 'JAVA net.properties cannot be located on this system'
  else
    Chef::Log.info('net_properties_locations: ' + net_properties_location)
    java_location = net_properties_location.strip
    java_location = java_location[0...-('/jre/lib/net.properties'.length)]
    Chef::Log.info('Java location: ' + java_location)
    java_location
  end
end