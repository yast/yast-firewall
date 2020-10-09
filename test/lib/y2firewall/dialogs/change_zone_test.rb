#!/usr/bin/env rspec
# Copyright (c) [2018] SUSE LLC
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

require_relative "../../../test_helper"

require "cwm/rspec"
require "y2firewall/dialogs/change_zone"
require "y2firewall/firewalld/interface"

describe Y2Firewall::Dialogs::ChangeZone do
  include_examples "CWM::Dialog"

  subject(:widget) { described_class.new(eth0) }

  let(:eth0) { Y2Firewall::Firewalld::Interface.new("eth0") }
end
