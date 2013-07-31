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
# File:	modules/SuSEFirewallUI.ycp
# Package:	Firewall configuration
# Summary:	UI for Firewall (Only for Firewall)
# Authors:	Lukas Ocilka <locilka@suse.cz>
# Internal
#
# $Id$
require "yast"

module Yast
  class SuSEFirewallUIClass < Module
    def main
      textdomain "firewall"

      @simple_text_output = false

      # Show details in the summary dialog?
      # Internal variable.
      @show_summary_details = false
    end

    # Returns whether summary should be more detailed.
    #
    # @return [Boolean] show detailed summary
    def GetShowSummaryDetails
      @show_summary_details
    end

    # Sets whether summary should be more detailed.
    #
    # @param boolean show detailed summary
    def SetShowSummaryDetails(set_show)
      @show_summary_details = set_show if set_show != nil

      nil
    end

    publish :variable => :simple_text_output, :type => "boolean"
    publish :function => :GetShowSummaryDetails, :type => "boolean ()"
    publish :function => :SetShowSummaryDetails, :type => "void (boolean)"
  end

  SuSEFirewallUI = SuSEFirewallUIClass.new
  SuSEFirewallUI.main
end
