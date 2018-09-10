# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2018 SUSE LLC
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

require "yast"
require "cwm/dialog"
require "y2firewall/widgets/overview"

Yast.import "Label"

module Y2Firewall
  module Dialogs
    # Main entry point to Firewall showing tree pager with all content
    class Main < CWM::Dialog
      def initialize
        textdomain "firewall"

        fw = Y2Firewall::Firewalld.instance
        fw.read
      end

      def title
        _("Firewall")
      end

      def contents
        MarginBox(
          0.5,
          0.5,
          Widgets::OverviewTreePager.new
        )
      end

      def run
        loop do
          result = super

          break unless result == :redraw
        end
      end

      def skip_store_for
        [:redraw]
      end

      def back_button
        # do not show back button when running on running system. See CWM::Dialog.back_button
        ""
      end

      def next_button
        Yast::Label.AcceptButton
      end

      def abort_button
        Yast::Label.AbortButton
      end

      # @return [Boolean] it aborts if returns true
      def abort_handler
        true
      end

      # @return [Boolean] it goes back if returns true
      def back_handler
        true
      end
    end
  end
end
