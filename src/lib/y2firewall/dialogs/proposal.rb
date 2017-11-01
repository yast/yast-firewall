# encoding: utf-8

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

require "yast"
require "cwm/dialog"
require "y2firewall/widgets/proposal"

Yast.import "Hostname"
Yast.import "Linuxrc"
Yast.import "Mode"

module Y2Firewall
  module Dialogs
    # Dialog for firewall and ssh proposal configuration
    class Proposal < CWM::Dialog
      def initialize(settings)
        textdomain "firewall"

        @settings = settings
      end

      def title
        _("Basic Firewall and SSH Configuration")
      end

      def contents
        VBox(
          Frame(
            _("Firewall and SSH service"),
            HSquash(
              MarginBox(
                0.5,
                0.5,
                VBox(
                  Left(Widgets::EnableFirewall.new(@settings)),
                  Left(Widgets::EnableSSHD.new(@settings)),
                  sshd_port_ui,
                  vnc_ports_ui
                )
              )
            )
          )
        )
      end

      def abort_button
        ""
      end

      def back_button
        # do not show back button when running on running system. See CWM::Dialog.back_button
        Yast::Mode.installation ? nil : ""
      end

      def next_button
        Yast::Mode.installation ? Yast::Label.OKButton : Yast::Label.FinishButton
      end

      def disable_buttons
        [:abort]
      end

    protected

      # Hostname of the current system.
      #
      # Getting the hostname is sometimes a little bit slow, so the value is
      # cached to be reused in every dialog redraw
      #
      # @return [String]
      def hostname
        @hostname ||= Yast::Hostname.CurrentHostname
      end

      def sshd_port_ui
        Left(Widgets::OpenSSHPort.new(@settings))
      end

      def vnc_ports_ui
        return Empty() unless Yast::Linuxrc.vnc

        Left(Widgets::OpenVNCPorts.new(@settings))
      end

      def should_open_dialog?
        true
      end
    end
  end
end
