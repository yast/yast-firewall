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
        Yast.import "NetworkInterfaces"
        textdomain "firewall"

        if Yast::Mode.config
          fw.read(minimal: true) unless fw.read?
        else
          Yast::NetworkInterfaces.Read
          fw.read unless fw.read?
        end
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
          swap_api if result == :swap_mode
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
        result == :redraw || result == :swap_mode
      end

      # Convenience method which return an instance of Y2Firewall::Firewalld
      #
      # @return [Y2Firewall::Firewalld] a firewalld instance
      def fw
        Y2Firewall::Firewalld.instance
      end

      # Modify the firewalld API instance in case the systemd service state has
      # changed.
      def swap_api
        fw.api = Y2Firewall::Firewalld::Api.new
      end

      # Writes down the firewall configuration and the systemd service
      # modifications
      def apply_changes
        return false if Yast::Mode.config
        # Firewall settings will be written into the permanent configurations only.
        # So the running firewalld service will not be changed. Even a reload does
        # not help (see man pages). So the running firewalld service has to be
        # restarted.
        # Set a flag only. Restarting will be done by system_service.save.
        if fw.modified? && # Data has been changed by user
            fw.system_service.running? &&      # The service is already running
            fw.system_service.action != :stop  # and will not be stopped by the user
          fw.system_service.restart
        end

        fw.write_only
        fw.system_service.save
      end
    end
  end
end
