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
# File:        firewall/generalfunctions
# Package:     Configuration YaST2 Firewall
# Summary:     General Handling Functions
# Authors:     Lukas Ocilka <locilka@suse.cz>
#
# $Id$
module Yast
  module FirewallGeneralfunctionsInclude
    def initialize_firewall_generalfunctions(include_target)
      textdomain "firewall"

      Yast.import "PortAliases"
    end

    # Function returns port name of port number got as parameter.
    # If no port name found, nil is returned.
    def GetPortName(port_to_be_checked)
      if port_to_be_checked == ""
        Builtins.y2error("Port name/number must be defined")
        return nil
      end
      # if port is a port name, find port number
      if Builtins.regexpmatch(port_to_be_checked, "^[0123456789]+$")
        port_aliases = PortAliases.GetListOfServiceAliases(port_to_be_checked)
        # clear port name
        port_to_be_checked = nil
        Builtins.foreach(port_aliases) do |port_alias|
          # if found port name in aliases, assigning port name instead of port number
          if !Builtins.regexpmatch(port_alias, "^[0123456789]+$")
            port_to_be_checked = port_alias
            raise Break
          end
        end
      end

      port_to_be_checked
    end
  end
end
