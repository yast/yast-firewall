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

require "y2firewall/widgets/zone"

module Y2Firewall
  module Dialogs
    class NameWidget < CWM::InputField
      def initialize(zone)
        @zone = zone
      end

      def init
        self.value = @zone.name
      end

      def label
        _("Name")
      end

      def validate
        return true if value.to_s.match?(/^\w+$/)

        Yast::Report.Error(_("Please, provide a valid alphanumeric name for the zone"))
        focus
        false
      end

      def store
        @zone.name = value
      end

      # Sets the focus into this widget
      def focus
        Yast::UI.SetFocus(Id(widget_id))
      end
    end

    class ShortWidget < CWM::InputField
      def initialize(zone)
        @zone = zone
      end

      def init
        self.value = @zone.short
      end

      def label
        _("Short")
      end

      def validate
        return false if value.to_s.empty?

        true
      end

      def store
        @zone.short = value
      end
    end

    class DescriptionWidget < CWM::InputField
      def initialize(zone)
        @zone = zone
      end

      def init
        self.value = @zone.description
      end

      def label
        _("Description")
      end

      def validate
        return true if !value.to_s.empty?

        Yast::Report.Error(_("The description of the zone cannot be empty"))
        false
      end

      def store
        @zone.description = value
      end
    end

    class TargetWidget < CWM::ComboBox
      def initialize(zone)
        @zone = zone
      end

      def label
        _("Target")
      end

      def init
        self.value = @zone.target || "default"
      end

      def items
        ["default", "ACCEPT", "%%REJECT%%", "DROP"].map { |s| [s, s] }
      end

      def store
        @zone.target = value
      end
    end

    class MasqueradeWidget < CWM::CheckBox
      def initialize(zone)
        @zone = zone
      end

      def label
        _("Masquerade")
      end

      def init
        self.value = !!@zone.masquerade?
      end

      def store
        @zone.masquerade = value
      end
    end
  end
end
