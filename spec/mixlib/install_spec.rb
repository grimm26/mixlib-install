#
# Author:: Thom May (<thom@chef.io>)
# Copyright:: Copyright (c) 2015 Chef, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "spec_helper"
require "mixlib/install/version"

describe Mixlib::Install do
  describe "#initialize" do
    it "sets a version" do
      install = Mixlib::Install.new("1.2.1")
      expect(install.version).to eq("1.2.1")
    end

    it "sets that powershell is used" do
      install = Mixlib::Install.new("1.2.1", true)
      expect(install.powershell).to be true
      expect(install.root).to eq("$env:systemdrive\\opscode\\chef")
    end

    describe "parses the options hash" do
      it "enables sudo" do
        opts = { sudo_command: "sudo -i -E" }
        install = Mixlib::Install.new("1.2.1", false, opts)
        expect(install.use_sudo).to be true
        expect(install.sudo_command).to eq("sudo -i -E")
      end

      it "sets the metadata endpoint" do
        opts = { endpoint: "chef-server" }
        install = Mixlib::Install.new("1.2.1", false, opts)
        expect(install.endpoint).to eq("metadata-chef-server")
      end
    end
  end

  describe "#install" do
    describe "on windows" do
      let(:installer) { Mixlib::Install.new("1.2.1", true, base: "http://f/") }
      let(:target_url) { "http://f/metadata?p=windows&m=x86_64&pv=2008r2&v=1.2.1" }

      it "generates config vars" do
        expect(installer).to receive(:install_command_vars_for_powershell)
        installer.install
      end

      it "creates the target url" do
        expect(installer).to receive(:windows_metadata_url).and_return(target_url)
        installer.install
      end

      it "builds the command string" do
        allow(installer).to receive(:install_command_vars_for_powershell).and_return("a test string")
        expect(installer).to receive(:shell_code_from_file).with("a test string")
        installer.install
      end
    end

    describe "on unix" do
      let(:installer) { Mixlib::Install.new("1.2.1", false, base: "http://f/", nightlies: true) }

      it "generates config vars" do
        expect(installer).to receive(:install_command_vars_for_bourne)
        installer.install
      end

      it "passes a flag to install a nightly" do
        expect(installer.install).to include('install_flags="-v 1.2.1 -n"')
      end

    end
  end
end