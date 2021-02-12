#!/usr/bin/env rspec

# ------------------------------------------------------------------------------
# Copyright (c) 2017 SUSE LLC
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact SUSE.
#
# To contact SUSE about this file by physical or electronic mail, you may find
# current contact information at www.suse.com.
# ------------------------------------------------------------------------------

require_relative "../../../test_helper.rb"

require "cwm/rspec"
require "y2firewall/dialogs/proposal"

describe Y2Firewall::Dialogs::Proposal do
  subject { described_class.new(settings) }

  let(:settings) { instance_double("Y2Firewall::ProposalSettings") }
  let(:selinux_configurable) { false }

  before do
    allow(subject).to receive(:selinux_configurable?)
      .and_return(selinux_configurable)
  end

  include_examples "CWM::Dialog"

  describe "#contents" do
    let(:widgets) { Yast::CWM.widgets_in_contents([subject.contents]) }
    let(:selinux_mode_widget) { widgets.find { |w| w.is_a?(Y2Firewall::Widgets::SelinuxMode) } }

    context "when SELinux is set to be configurable" do
      let(:selinux_configurable) { true }

      it "contains the Y2Firewall::Widgets::SelinuxMode content" do
        expect(selinux_mode_widget).to_not be_nil
      end
    end

    context "when SELinux is set to not be configurable" do
      let(:selinux_configurable) { false }

      it "does not contain the Y2Firewall::Widgets::SelinuxMode content" do
        expect(selinux_mode_widget).to be_nil
      end
    end
  end
end
