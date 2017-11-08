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
    class InstallationFinish < ::Installation::FinishClient
      attr_accessor :settings, :firewalld

      def initialize
        textdomain "firewall"
        @settings = ProposalSettings.instance
        @firewalld = Firewalld.instance
      end

      def title
        "Writing Firewall Configuration..."
      end

      def modes
        [:installation, :autoinst]
      end

      def write
        Service.Enable("sshd") if @settings.enable_sshd
        @firewalld.enable! if @settings.enable_firewall

        if @settings.open_ssh
          @firewalld.api.add_service("public", "ssh")
        else
          @firewalld.api.remove_service("public", "ssh")
        end

        @firewalld.api.add_service("public", "vnc-server") if @settings.open_vnc
      end
    end
  end
end
