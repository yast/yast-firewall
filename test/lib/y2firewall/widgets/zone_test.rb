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
require "y2firewall/widgets/zone"

describe Y2Firewall::Dialogs::NameWidget do
  before do
    allow(Yast::Report).to receive(:Error).with(/provide a valid alphanumeric name/)
  end

  subject { described_class.new(double(name: "test")) }

  include_examples "CWM::AbstractWidget"
end

describe Y2Firewall::Dialogs::ShortWidget do
  before do
    allow(Yast::Report).to receive(:Error).with(/provide a short name/)
  end

  subject { described_class.new(double(short: "test")) }

  include_examples "CWM::AbstractWidget"
end

describe Y2Firewall::Dialogs::DescriptionWidget do
  before do
    allow(Yast::Report).to receive(:Error).with(/provide a description/)
  end

  subject { described_class.new(double(description: "test")) }

  include_examples "CWM::AbstractWidget"
end

describe Y2Firewall::Dialogs::TargetWidget do
  subject { described_class.new(double(target: "default")) }

  include_examples "CWM::ComboBox"
end

describe Y2Firewall::Dialogs::MasqueradeWidget do
  subject { described_class.new(double(masquerade: false)) }

  include_examples "CWM::CheckBox"
end
