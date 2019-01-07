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
require "yast2/popup"
require "cwm/page"
require "y2firewall/firewalld"
require "y2firewall/ui_state"
require "y2firewall/dialogs/zone"
require "y2firewall/widgets/zones_table"
require "y2firewall/widgets/pages/zone"
require "y2firewall/widgets/zone_button"
require "y2firewall/helpers/interfaces"
require "y2firewall/widgets/default_zone_button"

module Y2Firewall
  module Widgets
    module Pages
      # A page for firewall zones:
      #   contains {ZonesTable}, has {Zone} as subpages.
      class Zones < CWM::Page
        include Y2Firewall::Helpers::Interfaces

        # Constructor
        #
        # @param _pager [CWM::TreePager]
        def initialize(_pager)
          textdomain "firewall"
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
            zones_table,
            Left(
              HBox(
                AddButton.new(self, zones_table),
                EditButton.new(self, zones_table),
                RemoveButton.new(self, zones_table),
                firewall.zones.empty? ? Empty() : default_zone_button
              )
            )
          )
        end

        # Add zone button
        class AddButton < ZoneButton
          def label
            _("Add")
          end

          def handle
            zone = Y2Firewall::Firewalld::Zone.new(name: "draft")
            result = Dialogs::Zone.run(zone, new_zone:       true,
                                             existing_names: firewall.zones.map(&:name))
            if result == :ok
              zone.relations.map { |r| zone.send("#{r}=", []) }
              firewall.zones << zone
              UIState.instance.select_row(zone.name)

              return :redraw
            end

            nil
          end
        end

        # Edit zone button
        class EditButton < ZoneButton
          def label
            _("Edit")
          end

          def handle
            zone = firewall.find_zone(@table.value.to_s)
            name = zone.name
            result = Dialogs::Zone.run(zone)
            UIState.instance.select_row(name) if result == :ok

            result == :ok ? :redraw : nil
          end
        end

        # Remove zone button
        class RemoveButton < ZoneButton
          def label
            _("Remove")
          end

          def handle
            zone = firewall.find_zone(@table.value.to_s)
            if Y2Firewall::Firewalld::Zone.known_zones.key?(zone.name)
              Yast2::Popup.show(_("Builtin zone cannot be removed."), headline: :error)
              return nil
            end

            firewall.remove_zone(zone.name)

            :redraw
          end
        end

      private

        def zones_table
          @zones_table ||= ZonesTable.new(firewall.zones, known_interfaces, default_zone_button)
        end

        def default_zone_button
          return nil if firewall.zones.empty?
          @default_zone_button ||= DefaultZoneButton.new(firewall.zones.first)
        end

        def firewall
          Y2Firewall::Firewalld.instance
        end
      end
    end
  end
end
