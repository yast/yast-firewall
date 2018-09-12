# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2018 SUSE LLC
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
require "cwm/page"
require "y2firewall/firewalld"
require "y2firewall/helpers/interfaces"
require "y2firewall/widgets/interfaces_table"

module Y2Firewall
  module Widgets
    module Pages
      # A page for network interfaces, has {Interface} as subpages
      class Interfaces < CWM::Page
        include Y2Firewall::Helpers::Interfaces

        # Constructor
        #
        # @param pager [CWM::TreePager]
        def initialize(_pager)
          textdomain "firewall"
        end

        # @macro seeAbstractWidget
        def label
          _("Interfaces")
        end

        # @macro seeCustomWidget
        def contents
          return @contents if @contents
          @contents = VBox(
            Left(Heading(_("Interfaces"))),
            InterfacesTable.new(known_interfaces)
          )
        end
      end

      # A page for one network interface
      class Interface < CWM::Page
        # Constructor
        #
        # @param interface [Hash<String,String>] "id", "name" and "zone"
        # @param pager [CWM::TreePager]
        def initialize(interface, _pager)
          textdomain "firewall"
          @interface = interface
          @sb = ZoneBox.new(interface)
          self.widget_id = "ifc:" + label
        end

        # @macro seeAbstractWidget
        def label
          @interface["id"]
        end

        # @macro seeCustomWidget
        def contents
          VBox(@sb)
        end

        # Selecting a zone to which an interface belongs
        class ZoneBox < CWM::SelectionBox
          # @param interface [Hash<String,String>] "id", "name" and "zone"
          def initialize(interface)
            textdomain "firewall"
            @interface = interface
            @zones = Y2Firewall::Firewalld.instance.zones
          end

          def label
            format(_("Zone for Interface %s"), @interface["id"])
          end

          def items
            @zones.map { |z| [z.name, z.name] }
          end

          def init
            self.value = @interface["zone"]
          end
        end
      end
    end
  end
end
