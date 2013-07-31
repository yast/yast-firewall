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
#
# File:	firewall/wizards.ycp
# Package:	Firewall configuration
# Summary:	Wizards definition
# Authors:	Lukas Ocilka <locilka@suse.cz>
#
# $Id$
module Yast
  module FirewallComplexInclude
    def initialize_firewall_complex(include_target)
      textdomain "firewall"

      Yast.import "Popup"
      Yast.import "SuSEFirewall"
      Yast.import "Wizard"
      Yast.import "Confirm"
      Yast.import "Report"
      Yast.import "Message"

      Yast.include include_target, "firewall/helps.rb"
    end

    # Read settings dialog.
    #
    # @return `next if success, else `abort
    def ReadDialog
      Wizard.RestoreHelp(HelpForDialog("reading_configuration"))

      # Checking for root's permissions
      return :abort if !Confirm.MustBeRoot

      # reading firewall settings
      ret = SuSEFirewall.Read
      if !ret
        Report.Error(Message.CannotContinueWithoutPackagesInstalled)
        return :abort
      end

      # testing for other firewall running
      if SuSEFirewall.IsOtherFirewallRunning
        # TRANSLATORS: Popup headline
        if Popup.ContinueCancelHeadline(
            _("Another Firewall Active"),
            # TRANSLATORS: Popup text
            _(
              "Another kind of firewall is active in your system.\n" +
                "If you continue, SuSEfirewall2 may produce undefined errors.\n" +
                "It would be better to remove the other firewall before\n" +
                "configuring SuSEfirewall2.\n" +
                "Continue with configuration?\n"
            )
          ) != true
          return :abort
        end
      end

      # hidding finished progress
      Wizard.SetContentsButtons("", Empty(), "", "", "")
      Wizard.SetAbortButton(:abort, Label.CancelButton)

      # FIXME: handle possible read errors
      ret ? :next : :abort
    end

    # Write settings dialog
    # @return `next if success, else `abort
    def WriteDialog
      Wizard.RestoreHelp(HelpForDialog("saving_configuration"))

      ret = SuSEFirewall.Write
      return ret ? :next : :abort

      # hidding finished progress
      Wizard.SetContentsButtons("", Empty(), "", "", "")
      Wizard.SetAbortButton(:abort, Label.CancelButton)
    end

    # Returns whether user confirmed aborting the configuration.
    #
    # @return [Boolean] result
    def AbortDialog
      if SuSEFirewall.GetModified
        return Popup.YesNoHeadline(
          # TRANSLATORS: popup headline
          _("Aborting Firewall Configuration"),
          # TRANSLATORS: popup message
          _("All changes would be lost.\nReally abort configuration?\n")
        )
      else
        return true
      end
    end
  end
end
