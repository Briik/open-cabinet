# describe 'discover_java_location' do
#   context 'jre is on system' do
#
#     it 'returns the root jdk dir' do
#       expect(self).to_receive(:discover_java_net_properties_location)
#                   .and_return('/usr/lib/jre/lib/net.properties')
#
#       expect(discover_java_location).to eq '/usr/lib'
#     end
#   end
#
#
#   context 'jre is not on system' do
#     it 'raises an exception' do
#       expect(self).to_receive(:discover_java_net_properties_location)
#                   .and_return('')
#
#       expect { discover_java_location }.to raise_error
#     end
#   end
# end
