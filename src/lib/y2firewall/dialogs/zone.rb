# encoding: utf-8

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

require "cwm/popup"
require "y2firewall/widgets/zone"

module Y2Firewall
  module Dialogs
    # Dialog for add/modify zone
    class Zone < CWM::Popup
      def initialize(zone, new_zone = false)
        textdomain "firewall"
        @zone = zone
        @new_zone = new_zone
      end

      def title
        @new_zone ? _("Adding new zone") : format(_("Editing zone '%s'") % @zone.name)
      end

      def contents
        MinWidth(70,
          VBox(
            # do not allow to change name for already created zone
            Left(NameWidget.new(@zone, disabled: !@new_zone)),
            VSpacing(1),
            Left(ShortWidget.new(@zone)),
            VSpacing(1),
            Left(DescriptionWidget.new(@zone)),
            VSpacing(1),
            Left(TargetWidget.new(@zone)),
            VSpacing(1),
            Left(MasqueradeWidget.new(@zone))
          ))
      end

      def abort_button
        Yast::Label.CancelButton
      end

    private

      def min_height
        10
      end
    end
  end
end
