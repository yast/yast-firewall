#!/usr/bin/env rspec
# encoding: utf-8

# Copyright (c) [2017] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require_relative "../../../test_helper.rb"
require "y2firewall/clients/proposal"

describe Y2Firewall::Clients::Proposal do
  subject(:client) { described_class.new }
  let(:proposal_settings) { Y2Firewall::ProposalSettings.instance }

  before do
    # skip bootloader proposal to avoid build dependency on it
    allow(subject).to receive(:cpu_mitigations_proposal)
  end

  describe "#initialize" do
    it "instantiates a new proposal settings" do
      expect(Y2Firewall::ProposalSettings).to receive(:instance)

      described_class.new
    end
  end

  describe "#description" do
    it "returns a hash with 'id', 'rich_text_title' and 'menu_title'" do
      description = client.description
      expect(description).to be_a Hash
      expect(description).to include("id", "menu_title", "rich_text_title")
    end
  end

  describe "#ask_user" do
    let(:param) { { "chosen_id" => action } }
    let(:dialog) { instance_double(Y2Firewall::Dialogs::Proposal) }

    before do
      allow(Y2Firewall::Dialogs::Proposal).to receive(:new).and_return(dialog)
    end

    context "when 'chosen_id' is equal to the description id" do
      let(:action) { client.description["id"] }

      it "runs the proposal dialog" do
        expect(dialog).to receive(:run)

        client.ask_user(param)
      end

      it "returns a hash with the proposal dialog result for 'workflow_sequence' key" do
        allow(dialog).to receive(:run).and_return(:result)

        result = client.ask_user(param)
        expect(result).to be_a(Hash)
        expect(result["workflow_sequence"]).to eq :result
      end
    end

    context "when 'chosen_id' corresponds to some of the services links" do
      let(:action) { Y2Firewall::Clients::Proposal::SERVICES_LINKS.first }

      it "calls the corresponding action for the chosen link" do
        expect(client).to receive("call_proposal_action_for").with(action)

        client.ask_user(param)
      end

      it "returns a hash with :next for 'workflow_sequence' key" do
        result = client.ask_user(param)
        expect(result).to be_a(Hash)
        expect(result["workflow_sequence"]).to eq :next
      end
    end
  end

  describe "#make_proposal" do
    let(:firewall_enabled) { false }
    let(:selinux_configurable) { false }

    before do
      allow(proposal_settings).to receive("enable_firewall")
        .and_return(firewall_enabled)
      allow(proposal_settings.selinux_config).to receive(:configurable?)
        .and_return(selinux_configurable)
      allow(Yast::Bootloader).to receive(:kernel_param).and_return(:missing)
    end

    it "returns a hash with 'preformatted_proposal', 'links' and 'warning_level'" do
      allow(Yast::HTML).to receive("List").and_return("<ul><li>Proposal link</li></ul>")

      proposal = client.make_proposal({})
      expect(proposal).to be_a Hash
      expect(proposal).to include("preformatted_proposal", "links", "warning_level")
    end

    context "when SELinux is configurable" do
      let(:selinux_configurable) { true }

      it "contains the SELinux Default Mode in preformatted proposal" do
        proposal = client.make_proposal({})

        expect(proposal["preformatted_proposal"]).to include("SELinux Default Mode")
      end
    end

    context "when SELinux is not configurable" do
      it "does not contain references to it in preformatted proposal" do
        proposal = client.make_proposal({})

        expect(proposal["preformatted_proposal"]).to_not include("SELinux Default Mode")
      end
    end

    context "when firewalld is disabled" do
      it "returns the 'preformatted_proposal' without links to open/close ports" do
        proposal = client.make_proposal({})

        expect(proposal["preformatted_proposal"]).to_not include("port")
      end
    end

    context "when firewalld is enabled" do
      let(:firewall_enabled) { true }

      it "returns the 'preformatted_proposal' with links to open/close ports" do
        proposal = client.make_proposal({})

        expect(proposal["preformatted_proposal"]).to include("port")
      end
    end
  end
end
