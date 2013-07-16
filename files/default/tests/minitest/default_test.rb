# vim: ft=ruby

describe 'trac' do
  require 'chef/mixin/shell_out'
  include Chef::Mixin::ShellOut
  include MiniTest::Chef::Assertions
  include MiniTest::Chef::Context
  include MiniTest::Chef::Resources

  it 'installs trac' do
    file('/usr/bin/trac-admin').must_exist
  end

  it 'installs subversion' do
    file('/usr/bin/svnadmin').must_exist
  end

end
