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
require "cwm/tabs"
require "y2firewall/firewalld"
require "y2firewall/widgets/zones_table"

module Y2Firewall
  module Widgets
    module Pages
      class Zones < CWM::Page
        # Constructor
        #
        # @param pager [CWM::TreePager]
        def initialize(pager)
          textdomain "firewall"
          firewall.read # FIXME when?
        end

        # @macro seeAbstractWidget
        def label
          _("Zones")
        end

        # @macro seeCustomWidget
        def contents
          return @contents if @contents
          @contents = VBox(
            Left(Heading(_("Zones"))),
            ZonesTable.new(firewall.zones)
          )
        end

      private

        def firewall
          Y2Firewall::Firewalld.instance
        end
      end

      # A page for a firewall zone
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

      # A Tab for ports in a firewall zone
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

      # A Tab for services in a firewall zone
      class ServicesTab < CWM::Tab
        # Constructor
        #
        # @param zone [Y2Firewall::Firewalld::Zone]
        # @param pager [CWM::TreePager]
        def initialize(zone, _pager)
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

        # A list of services in a firewall zone
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
