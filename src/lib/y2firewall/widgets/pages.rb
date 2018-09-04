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
require "cwm/tabs"
require "ui/service_status"
require "y2firewall/firewalld"

module Y2Firewall
  module Widgets
    module Pages
      class Startup < CWM::Page
         # Constructor
        #
        # @param pager [CWM::TreePager]
        def initialize(pager)
          textdomain "firewall"
          Yast.import "SystemdService"

          @service = Yast::SystemdService.find("firewalld")
          # This is a generic widget in SLE15; may not be appropriate.
          # For SLE15-SP1, use CWM::ServiceWidget
          @status_widget = ::UI::ServiceStatus.new(@service)
        end

        # @macro seeAbstractWidget
        def label
          "Startup" # FIXME
        end

        # @macro seeCustomWidget
        def contents
          VBox(
            @status_widget.widget,
            VStretch()
          )
        end
      end

      class Interfaces < CWM::Page
        # Constructor
        #
        # @param pager [CWM::TreePager]
        def initialize(pager)
          textdomain "firewall"
          @fw = Y2Firewall::Firewalld.instance
          @fw.read # FIXME when?
        end

        # @macro seeAbstractWidget
        def label
          "Interfaces" # FIXME
        end

        # @macro seeCustomWidget
        def contents
          Label("TODO: List of interfaces here")
        end
      end

      class Interface < CWM::Page
        # Constructor
        #
        # @param interface [Hash<String,String>] "id", "name" and "zone"
        # @param pager [CWM::TreePager]
        def initialize(interface, pager)
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

        class ZoneBox < CWM::SelectionBox
          # @param interface [Hash<String,String>] "id", "name" and "zone"
          def initialize(interface)
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

      class Zones < CWM::Page
        # Constructor
        #
        # @param pager [CWM::TreePager]
        def initialize(pager)
          textdomain "firewall"
          @fw = Y2Firewall::Firewalld.instance
          @fw.read # FIXME when?
        end

        # @macro seeAbstractWidget
        def label
          "Zones" # FIXME
        end

        # @macro seeCustomWidget
        def contents
          Label("TODO: List of zones here")
        end
      end

      class Zone < CWM::Page
        # Constructor
        #
        # @param zone [Y2Firewall::Firewalld::Zone]
        # @param pager [CWM::TreePager]
        def initialize(zone, pager)
          textdomain "firewall"
          @zone = zone
          @pager = pager
          self.widget_id = "z:" + zone.name
        end

        # @macro seeAbstractWidget
        def label
          @zone.name
        end

        # @macro seeCustomWidget
        def contents
          VBox(
            CWM::Tabs.new(
              ServicesTab.new(@zone, @pager),
              PortsTab.new
            )
          )
        end
      end

      class PortsTab < CWM::Tab
        def label
          _("Ports")
        end

        def contents
          VBox(
            VStretch(),
            HStretch()
          )
        end
      end

      class ServicesTab < CWM::Tab
        # Constructor
        #
        # @param zone [Y2Firewall::Firewalld::Zone]
        # @param pager [CWM::TreePager]
        def initialize(zone, pager)
          textdomain "firewall"
          @zone = zone
          @sb = ServiceBox.new(zone)
          self.widget_id = "zs:" + zone.name
        end

        def label
          _("Services")
        end

        # @macro seeCustomWidget
        def contents
          VBox(@sb)
        end

        class ServiceBox < CWM::MultiSelectionBox
          # @param zone [Y2Firewall::Firewalld::Zone]
          def initialize(zone)
            @zone = zone
          end

          def label
            # TRANSLATORS: %s is a zone name
            format(_("Services for %s") % @zone.name)
          end

          def items
            all_known_services = Y2Firewall::Firewalld.instance.api.services
            all_known_services.map { |s| [s, s] }
          end

          def init
            self.value = @zone.services
          end
        end
      end
    end
  end
end
