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
require "ui/service_status"
require "y2firewall/firewalld"
require "y2partitioner/widgets/tabs"

def all_known_services
  names = Y2Firewall::Firewalld.instance.api.services
  # services = names.map { |n| Y2Firewall::Firewalld.instance.find_service(n) }
  # services.map { |s| Item(Id(s.name), s.name) }
  names.map { |s| Item(Id(s), s) }
end

module Y2Firewall
  module Widgets
    module Pages
      class Startup < CWM::Page
         # Constructor
        #
        # @param pager [CWM::TreePager]
        def initialize(pager)
          textdomain "firewall"
          # Yast.import "SystemdService"

          # @service = Yast::SystemdService.find("firewalld")
          # # This is a generic widget in SLE15; may not be appropriate.
          # # For SLE15-SP1, use CWM::ServiceWidget
          # @status_widget = ::UI::ServiceStatus.new(@service)
        end

        # @macro seeAbstractWidget
        def label
          "Startup" # FIXME
        end

        # @macro seeCustomWidget
        def contents
          Label("Service")
          # VBox(
          #   @status_widget.widget,
          #   VStretch()
          # )
        end
      end

      class AllowedServices < CWM::Page
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
          Label("nothing here? select zone? or zones here?")
        end
      end

      # long list
      class ServicesTab < CWM::Tab
        def initialize(zone)
          textdomain "firewall"
          @zone = zone
          self.widget_id = "services:#{zone.name}"
        end

        def label
          _("Services")
        end

        def contents
          VBox(Label("Services"))
          VBox(AllowedServicesForZone::ServiceBox.new(@zone))
        end
      end

      # two lists (horizontal layout)
      class ServicesTab2 < CWM::Tab
        def initialize(zone)
          textdomain "firewall"
          @zone = zone
          self.widget_id = "services2:#{zone.name}"
        end

        def label
          _("Services")
        end

        def contents
          HBox(
            VBox(
              Left(Label("Available Services")),
              Table(
                Id("services_table"),
                Header(
                  "Name"
                ),
                all_known_services,
              ),
            ),
            VBox(
              PushButton(Id("add"), ">>"),
              PushButton(Id("remove"), "<<")
            ),
            VBox(
              Left(Label("Allowed Services")),
              Table(
                Id("services_table_2"),
                Header('Name'),
                [Item(Id("ssh"), "ssh")]
              )
            )
          )
        end
      end

      # old style
      class ServicesTab3 < CWM::Tab
        def initialize(zone)
          textdomain "firewall"
          @zone = zone
          self.widget_id = "services3:#{zone.name}"
        end

        def label
          _("Services")
        end

        def contents
          HBox(
            VBox(
              Left(ComboBox(
                Id("services_combo"),
                "Service to Allow",
                all_known_services
              )),
              Table(
                Id("services_table_2"),
                Header('Name'),
                [Item(Id("ssh"), "ssh")]
              )
            ),
            VBox(
              PushButton(Id("add"), "Add"),
              PushButton(Id("remove"), "Delete"),
              VStretch()
            ),
            HStretch()
          )
        end
      end

      # two lists (vertical layout)
      class ServicesTab4 < CWM::Tab
        def initialize(zone)
          textdomain "firewall"
          @zone = zone
          self.widget_id = "services2:#{zone.name}"
        end

        def label
          _("Services")
        end

        def contents
          VBox(
            VBox(
              Left(Label("Available Services")),
              Table(
                Id("services_table"),
                Header(
                  "Name"
                ),
                all_known_services,
              ),
            ),
            HBox(
              PushButton(Id("add"), "↓"),
              PushButton(Id("remove"), "↑")
            ),
            VBox(
              Left(Label("Allowed Services")),
              Table(
                Id("services_table_2"),
                Header('Name'),
                [Item(Id("ssh"), "ssh")]
              )
            )
          )
        end
      end

      class PortsTab < CWM::Tab
        def initialize(zone)
          textdomain "firewall"
          @zone = zone
          self.widget_id = "ports:#{zone.name}"
        end

        def label
          _("Ports")
        end

        def contents
          VBox(Label("Ports"))
        end
      end


      class AllowedServicesForZone < CWM::Page
        # Constructor
        #
        # @param zone [Y2Firewall::Firewalld::Zone]
        # @param pager [CWM::TreePager]
        def initialize(zone, pager)
          textdomain "firewall"
          @zone = zone
          @sb = ServiceBox.new(zone)
          self.widget_id = "asz:" + zone.name
        end

        # @macro seeAbstractWidget
        def label
          "#{@zone.name}" # FIXME
        end

        # @macro seeCustomWidget
        def contents
          # VBox(@sb)

          VBox(
            # Left(
            #   HBox(
            #     Heading("Services")
            #   )
            # ),
            tabs
          )
        end

        class ServiceBox < CWM::MultiSelectionBox
          # @param zone [Y2Firewall::Firewalld::Zone]
          def initialize(zone)
            @zone = zone
          end

          def label
            _("Services")
          end

          def items
            all_known_services = Y2Firewall::Firewalld.instance.api.services
            all_known_services.map { |s| [s, s] }
          end

          def init
            self.value = @zone.services
          end
        end

      private

        def tabs
          tabs = [
            # ServicesTab.new(@zone),
            ServicesTab4.new(@zone),
            PortsTab.new(@zone)
          ]
          ::CWM::Tabs.new(*tabs)
        end
      end

      class Interfaces < CWM::Page
         # Constructor
        #
        # @param pager [CWM::TreePager]
        def initialize(pager)
          textdomain "firewall"
          # Yast.import "SystemdService"

          # @service = Yast::SystemdService.find("firewalld")
          # # This is a generic widget in SLE15; may not be appropriate.
          # # For SLE15-SP1, use CWM::ServiceWidget
          # @status_widget = ::UI::ServiceStatus.new(@service)
        end

        # @macro seeAbstractWidget
        def label
          "Interfaces" # FIXME
        end

        # @macro seeCustomWidget
        def contents
          Label("Interfaces table")
          # VBox(
          #   @status_widget.widget,
          #   VStretch()
          # )
        end
      end

      class Logging < CWM::Page
         # Constructor
        #
        # @param pager [CWM::TreePager]
        def initialize(pager)
          textdomain "firewall"
          # Yast.import "SystemdService"

          # @service = Yast::SystemdService.find("firewalld")
          # # This is a generic widget in SLE15; may not be appropriate.
          # # For SLE15-SP1, use CWM::ServiceWidget
          # @status_widget = ::UI::ServiceStatus.new(@service)
        end

        # @macro seeAbstractWidget
        def label
          "Logging Level" # FIXME
        end

        # @macro seeCustomWidget
        def contents
          Label("Logging Level")
          # VBox(
          #   @status_widget.widget,
          #   VStretch()
          # )
        end
      end
    end
  end
end
