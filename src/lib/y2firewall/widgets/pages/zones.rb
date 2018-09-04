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
          "Zones" # FIXME
        end

        def all_known_zones
          Y2Firewall::Firewalld.instance.zones.map { |z| Item(Id(z.name), z.name, z.short) }
        end

        # @macro seeCustomWidget
        def contents
          VBox(
            Left(Label("Configured Zones")),
            Table(
              Id("zones_table"),
              Header(
                "Id",
                "Name"
              ),
              all_known_zones
            ),
            Left(
              HBox(
                PushButton(Id("add"), "Add"),
                PushButton(Id("add"), "Edit"),
                PushButton(Id("remove"), "Remove")
              )
            )
          )
        end
      end
    end
  end
end
