require 'spec_helper'

describe 'Ubuntu 14.04 stemcell image', stemcell_image: true do
  it_behaves_like 'All Stemcells'

  context 'installed by image_install_grub', {exclude_on_ppc64le: true} do
    describe file('/boot/grub/grub.conf') do
      it { should be_file }
      it { should contain 'default=0' }
      it { should contain 'timeout=1' }
      its(:content) { should match %r{^title Ubuntu 14\.04.* LTS \(.*\)$} }
      it { should contain '  root (hd0,0)' }
      its(:content) { should match %r{kernel /boot/vmlinuz-\S+-generic ro root=UUID=} }
      it { should contain ' selinux=0' }
      it { should contain ' cgroup_enable=memory swapaccount=1' }
      it { should contain ' console=tty0 console=ttyS0,115200n8' }
      it { should contain ' earlyprintk=ttyS0 rootdelay=300' }
      its(:content) { should match %r{initrd /boot/initrd.img-\S+-generic} }

      it('should set the grub menu password (stig: V-38585)') { should contain /^password --md5 \*/ }
      it('should be of mode 600 (stig: V-38583)') { should be_mode('600') }
      it('should be owned by root (stig: V-38579)') { should be_owned_by('root') }
      it('should be grouped into root (stig: V-38581)') { should be_grouped_into('root') }
      it('audits processes that start prior to auditd (CIS-8.1.3)') { should contain ' audit=1' }
    end

    describe file('/boot/grub/menu.lst') do
      before { skip 'until aws/openstack stop clobbering the symlink with "update-grub"' }
      it { should be_linked_to('./grub.conf') }
    end
  end

  context 'installs recent version of unshare so it gets the -p flag', {
    exclude_on_aws: true,
    exclude_on_azure: true,
    exclude_on_google: true,
    exclude_on_vcloud: true,
    exclude_on_vsphere: true,
    exclude_on_openstack: true,
    exclude_on_softlayer: true,
  } do
    context 'so we can run upstart in as PID 1 in the container' do
      describe file('/var/vcap/bosh/bin/unshare') do
        it { should be_file }
        it { should be_executable }
        it { should be_owned_by('root') }
        it { should be_grouped_into('root') }
      end
    end
  end

  context 'installed by system_parameters' do
    describe file('/var/vcap/bosh/etc/operating_system') do
      it { should contain('ubuntu') }
    end
  end

  context 'installed by dev_tools_config' do
    describe file('/var/vcap/bosh/etc/dev_tools_file_list') do
      it { should contain('/usr/bin/gcc') }
    end
    end

  context 'static libraries to remove' do
    describe file('/var/vcap/bosh/etc/static_libraries_list') do
      it { should be_file }
      its (:content) { should contain(backend.run_command('find / -iname "*.a" | sort | uniq')[:stdout]) }
    end
  end

  context 'installed by bosh_harden' do
    describe 'disallow unsafe setuid binaries' do
      subject { backend.run_command('find -L / -xdev -perm +6000 -a -type f')[:stdout].split }

      it { should match_array(%w(/bin/su /usr/bin/sudo /usr/bin/sudoedit)) }
    end
  end

  context 'installed by system-network', {
    exclude_on_warden: true
  } do
    describe file('/etc/hostname') do
      it { should be_file }
      its (:content) { should eq('bosh-stemcell') }
    end
  end

  context 'installed by system-network on some IaaSes', {
    exclude_on_vsphere: true,
    exclude_on_vcloud: true,
    exclude_on_warden: true,
    exclude_on_azure: true,
    exclude_on_softlayer: true,
  } do
    describe file('/etc/network/interfaces') do
      it { should be_file }
      it { should contain 'auto lo' }
      it { should contain 'iface lo inet loopback' }
    end
  end

  context 'installed by system-azure-network', {
    exclude_on_aws: true,
    exclude_on_google: true,
    exclude_on_vcloud: true,
    exclude_on_vsphere: true,
    exclude_on_warden: true,
    exclude_on_openstack: true,
    exclude_on_softlayer: true,
  } do
    describe file('/etc/network/interfaces') do
      it { should be_file }
      it { should contain 'auto eth0' }
      it { should contain 'iface eth0 inet dhcp' }
    end
  end

  context 'installed by system_open_vm_tools', {
    exclude_on_aws: true,
    exclude_on_google: true,
    exclude_on_vcloud: true,
    exclude_on_warden: true,
    exclude_on_openstack: true,
    exclude_on_azure: true,
    exclude_on_softlayer: true,
  } do
    describe package('open-vm-tools') do
      it { should be_installed }
    end
  end

  context 'installed by system_softlayer_open_iscsi', {
      exclude_on_aws: true,
      exclude_on_google: true,
      exclude_on_vsphere: true,
      exclude_on_vcloud: true,
      exclude_on_warden: true,
      exclude_on_openstack: true,
      exclude_on_azure: true,
  } do
    describe package('open-iscsi') do
      it { should be_installed }
    end
  end

  context 'installed by system_softlayer_multipath_tools', {
      exclude_on_aws: true,
      exclude_on_google: true,
      exclude_on_vsphere: true,
      exclude_on_vcloud: true,
      exclude_on_warden: true,
      exclude_on_openstack: true,
      exclude_on_azure: true,
  } do
    describe package('multipath-tools') do
      it { should be_installed }
    end
  end

  context 'installed by image_vsphere_cdrom stage', {
    exclude_on_aws: true,
    exclude_on_google: true,
    exclude_on_vcloud: true,
    exclude_on_warden: true,
    exclude_on_openstack: true,
    exclude_on_azure: true,
    exclude_on_softlayer: true,
  } do
    describe file('/etc/udev/rules.d/60-cdrom_id.rules') do
      it { should be_file }
      its(:content) { should eql(<<HERE) }
# Generated by BOSH stemcell builder

ACTION=="remove", GOTO="cdrom_end"
SUBSYSTEM!="block", GOTO="cdrom_end"
KERNEL!="sr[0-9]*|xvd*", GOTO="cdrom_end"
ENV{DEVTYPE}!="disk", GOTO="cdrom_end"

# unconditionally tag device as CDROM
KERNEL=="sr[0-9]*", ENV{ID_CDROM}="1"

# media eject button pressed
ENV{DISK_EJECT_REQUEST}=="?*", RUN+="cdrom_id --eject-media $devnode", GOTO="cdrom_end"

# Do not lock CDROM drive when cdrom is inserted
# because vSphere will start asking questions via API.
# IMPORT{program}="cdrom_id --lock-media $devnode"
IMPORT{program}="cdrom_id $devnode"

KERNEL=="sr0", SYMLINK+="cdrom", OPTIONS+="link_priority=-100"

LABEL="cdrom_end"
HERE
    end
  end

  context 'installed by bosh_aws_agent_settings', {
    exclude_on_google: true,
    exclude_on_openstack: true,
    exclude_on_vcloud: true,
    exclude_on_vsphere: true,
    exclude_on_warden: true,
    exclude_on_azure: true,
    exclude_on_softlayer: true,
  } do
    describe file('/var/vcap/bosh/agent.json') do
      it { should be_valid_json_file }
      it { should contain('"Type": "HTTP"') }
    end
  end

  context 'installed by bosh_google_agent_settings', {
    exclude_on_aws: true,
    exclude_on_openstack: true,
    exclude_on_vcloud: true,
    exclude_on_vsphere: true,
    exclude_on_warden: true,
    exclude_on_azure: true,
    exclude_on_softlayer: true,
  } do
    describe file('/var/vcap/bosh/agent.json') do
      it { should be_valid_json_file }
      it { should contain('"Type": "InstanceMetadata"') }
    end
  end

  context 'installed by bosh_openstack_agent_settings', {
    exclude_on_aws: true,
    exclude_on_google: true,
    exclude_on_vcloud: true,
    exclude_on_vsphere: true,
    exclude_on_warden: true,
    exclude_on_azure: true,
    exclude_on_softlayer: true,
  } do
    describe file('/var/vcap/bosh/agent.json') do
      it { should be_valid_json_file }
      it { should contain('"CreatePartitionIfNoEphemeralDisk": true') }
      it { should contain('"Type": "ConfigDrive"') }
      it { should contain('"Type": "HTTP"') }
    end
  end

  context 'installed by bosh_vsphere_agent_settings', {
    exclude_on_aws: true,
    exclude_on_google: true,
    exclude_on_vcloud: true,
    exclude_on_openstack: true,
    exclude_on_warden: true,
    exclude_on_azure: true,
    exclude_on_softlayer: true,
  } do
    describe file('/var/vcap/bosh/agent.json') do
      it { should be_valid_json_file }
      it { should contain('"Type": "CDROM"') }
    end
  end

  context 'installed by bosh_softlayer_agent_settings', {
      exclude_on_aws: true,
      exclude_on_google: true,
      exclude_on_vcloud: true,
      exclude_on_vsphere: true,
      exclude_on_warden: true,
      exclude_on_azure: true,
      exclude_on_openstack: true,
  } do
    describe file('/var/vcap/bosh/agent.json') do
      it { should be_valid_json_file }
      it { should contain('"Type": "File"') }
      it { should contain('"SettingsPath": "/var/vcap/bosh/user_data.json"') }
      it { should contain('"UseRegistry": true') }
    end
  end

  describe 'mounted file systems: /etc/fstab should mount nfs with nodev (stig: V-38654) (stig: V-38652)' do
    describe file('/etc/fstab') do
      it { should be_file }
      its (:content) { should eq("# UNCONFIGURED FSTAB FOR BASE SYSTEM\n") }
    end
  end

  describe 'installed packages' do
    let(:dpkg_list_aws_ubuntu) { File.read(spec_asset('dpkg-list-aws-ubuntu.txt')) }
    let(:dpkg_list_vsphere_ubuntu) { File.read(spec_asset('dpkg-list-vsphere-ubuntu.txt')) }
    let(:dpkg_list_vcloud_ubuntu) { File.read(spec_asset('dpkg-list-vsphere-ubuntu.txt')) }
    let(:dpkg_list_warden_ubuntu) { File.read(spec_asset('dpkg-list-warden-ubuntu.txt')) }
    let(:dpkg_list_google_ubuntu) { File.read(spec_asset('dpkg-list-google-ubuntu.txt')) }
    let(:dpkg_list_openstack_ubuntu) { File.read(spec_asset('dpkg-list-openstack-ubuntu.txt')) }

    describe command("dpkg --list | cut -f3 -d ' ' | sed -E 's/(linux.*4.4).*/\\1/'"), {
      exclude_on_aws: true,
      exclude_on_google: true,
      exclude_on_vcloud: true,
      exclude_on_vsphere: true,
      exclude_on_warden: true,
      exclude_on_azure: true,
    } do
      its(:stdout) { should eq(dpkg_list_openstack_ubuntu) }
    end

    describe command("dpkg --list | cut -f3 -d ' ' | sed -E 's/(linux.*4.4).*/\\1/'"), {
      exclude_on_aws: true,
      exclude_on_vcloud: true,
      exclude_on_vsphere: true,
      exclude_on_warden: true,
      exclude_on_azure: true,
      exclude_on_openstack: true,
    } do
      its(:stdout) { should eq(dpkg_list_google_ubuntu) }
    end

    describe command("dpkg --list | cut -f3 -d ' ' | sed -E 's/(linux.*4.4).*/\\1/'"), {
      exclude_on_aws: true,
      exclude_on_google: true,
      exclude_on_vcloud: true,
      exclude_on_vsphere: true,
      exclude_on_azure: true,
      exclude_on_openstack: true,
    } do
      its(:stdout) { should eq(dpkg_list_warden_ubuntu) }
    end

    describe command("dpkg --list | cut -f3 -d ' ' | sed -E 's/(linux.*4.4).*/\\1/'"), {
      exclude_on_aws: true,
      exclude_on_google: true,
      exclude_on_vsphere: true,
      exclude_on_warden: true,
      exclude_on_azure: true,
      exclude_on_openstack: true,
    } do
      its(:stdout) { should eq(dpkg_list_vcloud_ubuntu) }
    end

    describe command("dpkg --list | cut -f3 -d ' ' | sed -E 's/(linux.*4.4).*/\\1/'"), {
      exclude_on_aws: true,
      exclude_on_google: true,
      exclude_on_vcloud: true,
      exclude_on_warden: true,
      exclude_on_azure: true,
      exclude_on_openstack: true,
    } do
      its(:stdout) { should eq(dpkg_list_vsphere_ubuntu) }
    end

    describe command("dpkg --list | cut -f3 -d ' ' | sed -E 's/(linux.*4.4).*/\\1/'"), {
      exclude_on_google: true,
      exclude_on_vcloud: true,
      exclude_on_vsphere: true,
      exclude_on_warden: true,
      exclude_on_azure: true,
      exclude_on_openstack: true,
    } do
      its(:stdout) { should eq(dpkg_list_aws_ubuntu) }
    end
  end
end

describe 'Ubuntu 14.04 stemcell tarball', stemcell_tarball: true do
  context 'installed by bosh_dpkg_list stage' do
    describe file("#{ENV['STEMCELL_WORKDIR']}/stemcell/stemcell_dpkg_l.txt") do
      it { should be_file }
      it { should contain 'Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend' }
      it { should contain 'ubuntu-minimal' }
    end
  end

  context 'installed by dev_tools_config stage' do
    describe file("#{ENV['STEMCELL_WORKDIR']}/stemcell/dev_tools_file_list.txt") do
      it { should be_file }
    end
  end
end
