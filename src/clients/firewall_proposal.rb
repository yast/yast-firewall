# encoding: utf-8

# ***************************************************************************
#
# Copyright (c) 2000 - 2012 Novell, Inc.
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#
# ***************************************************************************
# File:	clients/firewall_proposal.ycp
# Package:	Firewall configuration
# Summary:	Firewall configuration proposal
# Authors:	Lukas Ocilka <locilka@suse.cz>
#
# $Id$
module Yast
  class FirewallProposalClient < Client
    def main

      textdomain "firewall"

      # The main ()
      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("Firewall proposal started")
      Builtins.y2milestone("Arguments: %1", WFM.Args)

      Yast.import "SuSEFirewall"
      Yast.import "SuSEFirewallServices"
      Yast.import "SuSEFirewallProposal"
      Yast.import "Popup"
      Yast.import "Progress"
      Yast.import "ProductFeatures"
      Yast.import "Report"
      Yast.import "Service"

      Yast.include self, "firewall/helps.rb"

      @enable_ssh = ProductFeatures.GetBooleanFeature(
        "globals",
        "firewall_enable_ssh"
      )

      @func = Convert.to_string(WFM.Args(0))
      @param = Convert.to_map(WFM.Args(1))
      @ret = {}

      init_firewall_proposals

      # create a textual proposal
      if @func == "MakeProposal"
        @progress_orig = Progress.set(false)
        @force_reset = Ops.get_boolean(@param, "force_reset", false)

        if @force_reset
          SuSEFirewallProposal.Reset
          SuSEFirewallProposal.SetChangedByUser(false)
        end
        SuSEFirewallProposal.Propose
        # setting start-firewall to the same value as enable-firewall
        SuSEFirewall.SetStartService(SuSEFirewall.GetEnableService)
        # reseting modified-flag, until called Write
        SuSEFirewall.ResetModified

        @warning = nil
        @warning_level = nil
        @proposal = SuSEFirewallProposal.ProposalSummary

        @ret = {
          "preformatted_proposal" => Ops.get(@proposal, "output", ""),
          "warning_level"         => :warning,
          "warning"               => Ops.get(@proposal, "warning"),
          "links"                 => [
            "firewall--enable_firewall_in_proposal",
            "firewall--disable_firewall_in_proposal",
            "firewall--enable_ssh_in_proposal",
            "firewall--disable_ssh_in_proposal",
            "firewall--enable_vnc_in_proposal",
            "firewall--disable_vnc_in_proposal"
          ],
          "help"                  => HelpForDialog("installation_proposal")
        }

        Progress.set(@progress_orig)
      # run the module
      elsif @func == "AskUser"
        @chosen_id = Ops.get(@param, "chosen_id")
        Builtins.y2milestone(
          "Firewall Proposal wanted to change with id %1",
          @chosen_id
        )

        # When user clicks on any clickable <a href> in firewall proposal,
        # one of these actions is called

        # Package SuSEfirewall2 is not installed
        if !SuSEFirewall.SuSEFirewallIsInstalled
          # TRANSLATORS: message popup
          Report.Message(
            _(
              "Firewall configuration cannot be changed.\nThe SuSEfirewall2 package is not installed."
            )
          )
          @ret = { "workflow_sequence" => :next }

          # Enable firewall
        elsif @chosen_id == "firewall--enable_firewall_in_proposal"
          Builtins.y2milestone("Firewall enabled by a single-click")

          enable_firewall

          @ret = { "workflow_sequence" => :next }
          SuSEFirewallProposal.SetChangedByUser(true)

          # Disable firewall
        elsif @chosen_id == "firewall--disable_firewall_in_proposal"
          Builtins.y2milestone("Firewall disabled by a single-click")

          disable_firewall

          @ret = { "workflow_sequence" => :next }
          SuSEFirewallProposal.SetChangedByUser(true)

          # Enable SSH service
        elsif @chosen_id == "firewall--enable_ssh_in_proposal"
          Builtins.y2milestone("SSH enabled by a single-click")

          if SuSEFirewallServices.IsKnownService("service:sshd")
            Builtins.y2milestone("Service 'service:sshd' is known")
            SuSEFirewallProposal.OpenServiceOnNonDialUpInterfaces(
              "service:sshd",
              ["ssh"]
            )
          elsif SuSEFirewallServices.IsKnownService("ssh")
            Builtins.y2warning("Only service 'ssh' is known")
            SuSEFirewallProposal.OpenServiceOnNonDialUpInterfaces(
              "ssh",
              ["ssh"]
            )
          end

          @enable_ssh = true

          @ret = { "workflow_sequence" => :next }
          SuSEFirewallProposal.SetChangedByUser(true)

          # Disable SSH service
        elsif @chosen_id == "firewall--disable_ssh_in_proposal"
          Builtins.y2milestone("SSH disabled by a single-click")
          # new service definition
          if SuSEFirewallServices.IsKnownService("service:sshd")
            SuSEFirewall.SetServicesForZones(
              ["service:sshd"],
              SuSEFirewall.GetKnownFirewallZones,
              false
            )
          end
          # old service definition
          if SuSEFirewallServices.IsKnownService("ssh")
            SuSEFirewall.SetServicesForZones(
              ["ssh"],
              SuSEFirewall.GetKnownFirewallZones,
              false
            )
          end

          # SSH might be also defined by a port, not only using a service:sshd
          Builtins.foreach(SuSEFirewall.GetKnownFirewallZones) do |zone|
            if SuSEFirewall.HaveService("ssh", "TCP", zone)
              SuSEFirewall.RemoveService("ssh", "TCP", zone)
            end
          end

          @enable_ssh = false

          @ret = { "workflow_sequence" => :next }
          SuSEFirewallProposal.SetChangedByUser(true)

          # Enable VNC service
        elsif @chosen_id == "firewall--enable_vnc_in_proposal"
          Builtins.y2milestone("VNC enabled by a single-click")
          SuSEFirewallProposal.OpenServiceOnNonDialUpInterfaces(
            "service:xorg-x11-Xvnc",
            ["5801", "5901"]
          )
          @ret = { "workflow_sequence" => :next }
          SuSEFirewallProposal.SetChangedByUser(true)

          # Disable VNC service
        elsif @chosen_id == "firewall--disable_vnc_in_proposal"
          Builtins.y2milestone("VNC disabled by a single-click")
          SuSEFirewall.SetServicesForZones(
            ["service:xorg-x11-Xvnc"],
            SuSEFirewall.GetKnownFirewallZones,
            false
          )
          @ret = { "workflow_sequence" => :next }
          SuSEFirewallProposal.SetChangedByUser(true)

          # Change the firewall settings in usual configuration dialogs
        else
          @stored = SuSEFirewall.Export
          Builtins.y2milestone("Editing firewall settings")
          @result = Convert.to_symbol(WFM.CallFunction("firewall"))

          if @result != :next
            SuSEFirewall.Import(@stored)
          else
            SuSEFirewallProposal.SetChangedByUser(true)
          end

          Builtins.y2debug("stored=%1", @stored)
          Builtins.y2debug("result=%1", @result)
          @ret = { "workflow_sequence" => @result }
        end
      # create titles
      elsif @func == "Description"
        @ret = {
          # RichText label
          "rich_text_title" => _("Firewall"),
          # Menu label
          "menu_title"      => _("&Firewall"),
          "id"              => "firewall"
        }
      # write the proposal
      elsif @func == "Write"
        # Allways modified
        SuSEFirewall.SetModified
        SuSEFirewall.Write
        Service.Enable("sshd") if @enable_ssh
      else
        Builtins.y2error("unknown function: %1", @func)
      end

      # Finish
      Builtins.y2debug("ret=%1", @ret)
      Builtins.y2milestone("Firewall proposal finished")
      Builtins.y2milestone("----------------------------------------")
      deep_copy(@ret)

      # EOF
    end

    private
    def init_firewall_proposals
      # run this only once
      return if SuSEFirewallProposal.GetProposalInitialized

      # Package must be installed
      if SuSEFirewall.SuSEFirewallIsInstalled

        # read target firewall configuration
        SuSEFirewallProposal.Reset

        product_enable_firewall = ProductFeatures.GetBooleanFeature("globals", "enable_firewall")
        target_enable_firewall = SuSEFirewall.GetEnableService

        Builtins.y2milestone("Firewall enabled by product defaults: #{product_enable_firewall}")
        Builtins.y2milestone("Firewall enabled in 1st stage: #{target_enable_firewall}")

        # check if user changed settings during first stage
        SuSEFirewallProposal.SetChangedByUser(true) if product_enable_firewall != target_enable_firewall
      else
        Builtins.y2milestone(
          "Default firewall values: enable_firewall=%1, enable_ssh=%2",
          false,
          false
        )

        disable_firewall
      end


      SuSEFirewallProposal.SetProposalInitialized(true)
    end

    def enable_firewall
      SuSEFirewall.SetEnableService(true)
      SuSEFirewall.SetStartService(true)
    end

    def disable_firewall
      SuSEFirewall.SetEnableService(false)
      SuSEFirewall.SetStartService(false)
    end

  end
end

Yast::FirewallProposalClient.new.main
