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
        content = [Left(firewall_ssh_content)]
        content << Left(selinux_content) if selinux_configurable?

        HBox(
          HStretch(),
          VBox(
            VStretch(),
            *content,
            VStretch()
          ),
          HStretch()
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

      def selinux_configurable?
        @settings.selinux_config.configurable?
      end

      def firewall_ssh_content
        Frame(
          _("Firewall and SSH service"),
          HSquash(
            MarginBox(
              0.5,
              0.5,
              VBox(
                Widgets::FirewallSSHProposal.new(@settings)
              )
            )
          )
        )
      end

      def selinux_content
        Frame(
          _("SELinux"),
          MarginBox(
            0.5,
            0.5,
            VBox(
              Widgets::SelinuxMode.new(@settings)
            )
          )
        )
      end

      # Hostname of the current system.
      #
      # Getting the hostname is sometimes a little bit slow, so the value is
      # cached to be reused in every dialog redraw
      #
      # @return [String]
      def hostname
        @hostname ||= Yast::Hostname.CurrentHostname
      end

      def should_open_dialog?
        true
      end
    end
  end
end
