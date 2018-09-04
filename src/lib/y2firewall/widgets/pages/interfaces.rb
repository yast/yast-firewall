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

require "y2firewall/helpers/interfaces"

module Y2Firewall
  module Widgets
    module Pages
      class Interfaces < CWM::Page
        include Helpers::Interfaces

        # Constructor
        #
        # @param pager [CWM::TreePager]
        def initialize(_pager)
          textdomain "firewall"
          Yast::NetworkInterfaces.Read
        end

        def table_entries
          known_interfaces.map { |i| Item(Id(i["id"]), i["id"], i["name"], i["zone"]) }
        end

        # @macro seeAbstractWidget
        def label
          "Interfaces" # FIXME
        end

        # @macro seeCustomWidget
        def contents
          VBox(
            Left(Label("Interfaces bindings")),
            Table(
              Id("interfaces_table"),
              Header(
                "Id",
                "Name",
                "Zone"
              ),
              table_entries
            )
          )
        end
      end

      class Interface < CWM::Page
        # Constructor
        #
        # @param interface [String]
        # @param pager [CWM::TreePager]
        def initialize(interface, _pager)
          textdomain "firewall"
          @interface = interface
          @sb = ZoneBox.new(interface)
          self.widget_id = "ifc:" + interface
        end

        # @macro seeAbstractWidget
        def label
          @interface
        end

        # @macro seeCustomWidget
        def contents
          VBox(@sb)
        end

        class ZoneBox < CWM::SelectionBox
          # @param zone [Y2Firewall::Firewalld::Zone]
          def initialize(interface)
            @interface = interface
            @zones = Y2Firewall::Firewalld.instance.zones
          end

          def label
            format(_("Zone for Interface %s"), @interface)
          end

          def items
            @zones.map { |z| [z.name, z.name] }
          end

          def init
            zone = @zones.sample # FIXME
            self.value = zone.name
          end
        end
      end
    end
  end
end
