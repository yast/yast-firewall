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
require "y2firewall/widgets/overview_tree_pager"

Yast.import "Label"
Yast.import "Mode"
Yast.import "Popup"

module Y2Firewall
  module Dialogs
    # Main entry point to Firewall showing tree pager with all content
    class Main < CWM::Dialog
      # Constructor
      def initialize
        super()
        Yast.import "NetworkInterfaces"
        textdomain "firewall"

        unless Yast::Mode.config
          Yast::NetworkInterfaces.Read
          fw.read unless fw.read?
        end
        # For applying the changes to the running configuration a reload or
        # restart need to be applied.
        # Proposed a service reload by default (bsc#1114673, bsc#1121277)
        fw.system_service.reload if fw.system_service&.running?
      end

      def should_open_dialog?
        return true if Yast::Mode.config

        super
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

      # Runs the dialog
      #
      # @return [Symbol] result of the dialog
      def run
        result = nil

        loop do
          result = super
          break unless continue_running?(result)
        end

        apply_changes if result == :next
        result
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
        Yast::Mode.config ? Yast::Label.CancelButton : Yast::Label.AbortButton
      end

      # @return [Boolean] it aborts if returns true
      def abort_handler
        Yast::Popup.ReallyAbort(fw.modified?)
      end

      # @return [Boolean] it goes back if returns true
      def back_handler
        true
      end

    private

      # Whether the dialog run loop should continue or not
      #
      # @return [Boolean] true in case of a dialog redraw or an api change
      def continue_running?(result)
        result == :redraw
      end

      # Convenience method which return an instance of Y2Firewall::Firewalld
      #
      # @return [Y2Firewall::Firewalld] a firewalld instance
      def fw
        Y2Firewall::Firewalld.instance
      end

      # Writes down the firewall configuration and the systemd service
      # modifications
      def apply_changes
        return false if Yast::Mode.config

        fw.write_only
        fw.system_service.save
      end
    end
  end
end
