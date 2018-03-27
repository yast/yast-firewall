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
require "y2firewall/firewalld"
require "y2firewall/proposal_settings"
require "installation/finish_client"

module Y2Firewall
  module Clients
    # This is a step of base installation finish and it is responsible of write
    # the firewall proposal configuration for installation and autoinstallation
    # modes.
    class InstallationFinish < ::Installation::FinishClient
      include Yast::I18n

      # Y2Firewall::ProposalSettings instance
      attr_accessor :settings
      # Y2Firewall::Firewalld instance
      attr_accessor :firewalld

      # Constuctor
      def initialize
        textdomain "firewall"
        @settings = ProposalSettings.instance
        @firewalld = Firewalld.instance
      end

      def title
        _("Writing Firewall Configuration...")
      end

      def modes
        [:installation]
      end

      def write
        Service.Enable("sshd") if @settings.enable_sshd

        return true if !@firewalld.installed?

        @settings.enable_firewall ? @firewalld.enable! : @firewalld.disable!

        if @settings.open_ssh
          @firewalld.api.add_service(@settings.default_zone, "ssh")
        else
          @firewalld.api.remove_service(@settings.default_zone, "ssh")
        end

        @firewalld.api.add_service(@settings.default_zone, "vnc-server") if @settings.open_vnc

        true
      end
    end
  end
end
