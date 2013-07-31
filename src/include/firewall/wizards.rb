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
  module FirewallWizardsInclude
    def initialize_firewall_wizards(include_target)
      Yast.import "UI"
      Yast.import "Wizard"
      Yast.import "Sequencer"
      Yast.import "Label"

      Yast.include include_target, "firewall/complex.rb"
      Yast.include include_target, "firewall/dialogs.rb"
      Yast.include include_target, "firewall/uifunctions.rb"
    end

    # Main workflow of the firewall configuration
    #
    # @return [Object] returned value from Sequencer::Run() call
    def MainSequence
      aliases = { "configuration" => lambda { RunFirewallDialogs() } }

      sequence = {
        "ws_start"      => "configuration",
        "configuration" => { :abort => :abort, :next => :next }
      }

      Sequencer.Run(aliases, sequence)
    end

    # Whole configuration of firewall
    #
    # @return [Object] returned value from Sequencer::Run() call
    def FirewallSequence
      aliases = {
        "read"    => [lambda { ReadDialog() }, true],
        "main"    => lambda { MainSequence() },
        "summary" => lambda { BoxSummaryDialog() },
        "write"   => [lambda { WriteDialog() }, true]
      }

      sequence = {
        "ws_start" => "read",
        "read"     => { :abort => :abort, :next => "main" },
        "main"     => { :abort => :abort, :next => "summary" },
        "summary"  => { :abort => :abort, :next => "write" },
        "write"    => { :abort => :abort, :next => :next }
      }

      Wizard.CreateDialog
      Wizard.SetAbortButton(:abort, Label.CancelButton)
      SetFirewallIcon()

      ret = Sequencer.Run(aliases, sequence)

      UI.CloseDialog
      deep_copy(ret)
    end

    # Whole configuration of firewall
    #
    # @return [Object] returned value from Sequencer::Run() call
    def FirewallAutoSequence
      aliases = { "main" => lambda { MainSequence() }, "summary" => lambda do
        BoxSummaryDialog()
      end }

      sequence = {
        "ws_start" => "main",
        "main"     => { :abort => :abort, :next => :next }
      }

      Wizard.CreateDialog
      SetFirewallIcon()

      ret = Sequencer.Run(aliases, sequence)

      UI.CloseDialog
      deep_copy(ret)
    end

    # Whole configuration of firewall
    #
    # @return [Object] returned value from Sequencer::Run() call
    def FirewallInstallationSequence
      aliases = { "main" => lambda { MainSequence() }, "summary" => lambda do
        BoxSummaryDialog()
      end }

      sequence = {
        "ws_start" => "main",
        "main"     => { :abort => :abort, :next => :next }
      }

      Wizard.CreateDialog
      SetFirewallIcon()

      ret = Sequencer.Run(aliases, sequence)

      UI.CloseDialog
      deep_copy(ret)
    end
  end
end
