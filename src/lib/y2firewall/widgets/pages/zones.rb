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
require "y2firewall/ui_state"
require "y2firewall/dialogs/zone"
require "y2firewall/widgets/zones_table"
require "y2firewall/widgets/pages/zone"
require "y2firewall/widgets/zone_button"

module Y2Firewall
  module Widgets
    module Pages
      class Zones < CWM::Page
        # Constructor
        #
        # @param pager [CWM::TreePager]
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
                RemoveButton.new(self, zones_table)
              )
            )
          )
        end

        class AddButton < ZoneButton
          def label
            _("Add")
          end

          def handle
            zone = Y2Firewall::Firewalld::Zone.new(name: "draft")
            result = Dialogs::Zone.run(zone, true)
            if result == :ok
              zone.relations.map { |r| zone.send("#{r}=", []) }
              fw.zones << zone
              UIState.instance.select_row(zone.name)

              return :redraw
            end

            nil
          end
        end

        class EditButton < ZoneButton
          def label
            _("Edit")
          end

          def handle
            zone = fw.find_zone(@table.value.to_s)
            name = zone.name
            result = Dialogs::Zone.run(zone)
            UIState.instance.select_row(name) if result == :ok

            result == :ok ? :redraw : nil
          end
        end

        class RemoveButton < ZoneButton
          def label
            _("Remove")
          end

          def handle
            zone = fw.find_zone(@table.value.to_s)
            fw.remove_zone(zone.name)

            :redraw
          end
        end

      private

        def fw
          Y2Firewall::Firewalld.instance
        end

        def zones_table
          @zones_table ||= ZonesTable.new(fw.zones)
        end
      end
    end
  end
end
