#!/usr/bin/env ruby
#
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

require "yast"
require "y2firewall/firewalld/api"
require "y2firewall/proposal_settings"
require "y2firewall/dialogs/proposal"
require "installation/proposal_client"

module Y2Firewall
  module Clients
    # Firewall and SSH installation proposal client
    class Proposal < ::Installation::ProposalClient
      include Yast::I18n
      include Yast::Logger

      # [Y2Firwall::ProposalSettings] Stores the proposal settings
      attr_accessor :settings

      SERVICES_LINKS = [
        LINK_ENABLE_FIREWALL = "firewall--enable_firewall".freeze,
        LINK_DISABLE_FIREWALL = "firewall--disable_firewall".freeze,
        LINK_OPEN_SSH_PORT = "firewall--open_ssh".freeze,
        LINK_BLOCK_SSH_PORT = "firewall--close_ssh".freeze,
        LINK_ENABLE_SSHD = "firewall--enable_sshd".freeze,
        LINK_DISABLE_SSHD = "firewall--disable_sshd".freeze,
        LINK_OPEN_VNC = "firewall--open_vnc".freeze,
        LINK_CLOSE_VNC = "firewall--close_vnc".freeze,
        LINK_CPU_MITIGATIONS = "firewall--cpu_mitigations".freeze
      ].freeze

      LINK_FIREWALL_DIALOG = "firewall".freeze

      # Constructor
      def initialize
        Yast.import "UI"
        Yast.import "HTML"
        textdomain "firewall"

        @settings ||= ProposalSettings.instance
      end

      def description
        # TODO: temporary dgettext only to avoid new translation
        {
          # Proposal title
          "rich_text_title" => Yast::Builtins.dgettext("security", "Security"),
          # Menu entry label
          "menu_title"      => Yast::Builtins.dgettext("ncurses-pkg", "&Security"),
          "id"              => LINK_FIREWALL_DIALOG
        }
      end

      def make_proposal(_attrs)
        {
          "preformatted_proposal" => preformatted_proposal,
          "warning_level"         => :warning,
          "links"                 => SERVICES_LINKS
        }
      end

      def preformatted_proposal
        Yast::HTML.List(proposals)
      end

      def ask_user(param)
        chosen_link = param["chosen_id"]
        result = :next
        log.info "User clicked #{chosen_link}"

        if SERVICES_LINKS.include?(chosen_link)
          call_proposal_action_for(chosen_link)
        elsif chosen_link == LINK_FIREWALL_DIALOG
          result = Y2Firewall::Dialogs::Proposal.new(@settings).run
        else
          raise "INTERNAL ERROR: unknown action '#{chosen_link}' for proposal client"
        end

        { "workflow_sequence" => result }
      end

      def write
        { "success" => true }
      end

    private

      # Obtain and call the corresponding method for the clicked link.
      def call_proposal_action_for(link)
        action = link.gsub("firewall--", "")
        if action == "cpu_mitigations"
          bootloader_dialog
        else
          @settings.public_send("#{action}!")
        end
      end

      # Array with the available proposal descriptions.
      #
      # @return [Array<String>] services and ports descriptions
      def proposals
        # Filter proposals with content
        [cpu_mitigations_proposal, firewall_proposal, sshd_proposal,
         ssh_port_proposal, vnc_fw_proposal].compact
      end

      # Returns the cpu mitigation part of the bootloader proposal description
      # Returns nil if this part should be skipped
      # @return [String] proposal html text
      def cpu_mitigations_proposal
        require "bootloader/bootloader_factory"
        bl = ::Bootloader::BootloaderFactory.current
        return nil if bl.name == "none"

        mitigations = bl.cpu_mitigations

        res = _("CPU Mitigations: ") + format("<a href=\"%s\">", LINK_CPU_MITIGATIONS) +
          mitigations.to_human_string + "</a>"
        log.info "mitigations output #{res.inspect}"
        res
      end

      def bootloader_dialog
        require "bootloader/config_dialog"
        Yast.import "Bootloader"

        # do it in own dialog window
        Yast::Wizard.CreateDialog
        dialog = ::Bootloader::ConfigDialog.new(initial_tab: :kernel)
        settings = Yast::Bootloader.Export
        result = dialog.run
        if result != :next
          Yast::Bootloader.Import(settings)
        else
          Yast::Bootloader.proposed_cfg_changed = true
        end
      ensure
        Yast::Wizard.CloseDialog
      end

      # Returns the VNC-port part of the firewall proposal description
      # Returns nil if this part should be skipped
      # @return [String] proposal html text
      def vnc_fw_proposal
        # It only makes sense to show the blocked ports if firewall is
        # enabled (bnc#886554)
        return nil unless @settings.enable_firewall
        # Show VNC port only if installing over VNC
        return nil unless Linuxrc.vnc

        if @settings.open_vnc
          _("VNC ports will be open (<a href=\"%s\">block</a>)") % LINK_CLOSE_VNC
        else
          _("VNC ports will be blocked (<a href=\"%s\">open</a>)") % LINK_OPEN_VNC
        end
      end

      # Returns the SSH-port part of the firewall proposal description
      # Returns nil if this part should be skipped
      # @return [String] proposal html text
      def ssh_port_proposal
        return nil unless @settings.enable_firewall

        if @settings.open_ssh
          _("SSH port will be open (<a href=\"%s\">block</a>)") % LINK_BLOCK_SSH_PORT
        else
          _("SSH port will be blocked (<a href=\"%s\">open</a>)") % LINK_OPEN_SSH_PORT
        end
      end

      # Returns the Firewalld service part of the firewall proposal description
      # @return [String] proposal html text
      def firewall_proposal
        if @settings.enable_firewall
          _(
            "Firewall will be enabled (<a href=\"%s\">disable</a>)"
          ) % LINK_DISABLE_FIREWALL
        else
          _(
            "Firewall will be disabled (<a href=\"%s\">enable</a>)"
          ) % LINK_ENABLE_FIREWALL
        end
      end

      # Returns the SSH service part of the firewall proposal description
      # @return [String] proposal html text
      def sshd_proposal
        if @settings.enable_sshd
          _(
            "SSH service will be enabled (<a href=\"%s\">disable</a>)"
          ) % LINK_DISABLE_SSHD
        else
          _(
            "SSH service will be disabled (<a href=\"%s\">enable</a>)"
          ) % LINK_ENABLE_SSHD
        end
      end
    end
  end
end
