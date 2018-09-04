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
require "y2firewall/widgets/pages/startup"
require "y2firewall/widgets/pages/zones"
require "y2firewall/widgets/pages/interfaces"

def firewalld
  Y2Firewall::Firewalld.instance
end

def all_known_services
  names = firewalld.current_service_names
  names.map { |s| Item(Id(s), s) }
end

module Y2Firewall
  module Widgets
    module Pages
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
          VBox(Zone::ServiceBox.new(@zone))
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
          _("Services Proposal 2")
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
                all_known_services
              )
            ),
            VBox(
              PushButton(Id("add"), ">>"),
              PushButton(Id("remove"), "<<")
            ),
            VBox(
              Left(Label("Allowed Services")),
              Table(
                Id("services_table_2"),
                Header("Name"),
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
                Header("Name"),
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
          _("Services Proposal 4")
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
                all_known_services
              )
            ),
            HBox(
              PushButton(Id("add"), "↓"),
              PushButton(Id("remove"), "↑")
            ),
            VBox(
              Left(Label("Allowed Services")),
              Table(
                Id("services_table_2"),
                Header("Name"),
                [Item(Id("ssh"), "ssh")]
              )
            )
          )
        end
      end

      # old style
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
          VBox(
            HBox(
              VBox(
                InputField(Id("tcp_ports"), Opt(:hstretch), "TCP Ports", "7000,8000-8010"),
                InputField(Id("udp_ports"), Opt(:hstretch), "UDP Ports"),
                InputField(Id("rpc_ports"), Opt(:hstretch), "RPC Ports"),
                InputField(Id("ip_ports"), Opt(:hstretch), "IP Ports")
              )
            ),
            VStretch()
          )
        end
      end

      class PortsTab2 < CWM::Tab
        def initialize(zone)
          textdomain "firewall"
          @zone = zone
          self.widget_id = "ports:#{zone.name}"
        end

        def label
          _("Ports")
        end

        def contents
          HBox(
            VBox(
              HBox(
                InputField(Id("port"), Opt(:hstretch), "Port"),
                ComboBox(
                  Id("proto_combo"),
                  "Protocol",
                  [Item(Id("tcp"), "TCP")]
                )
              ),
              Table(
                Id("ports_table_2"),
                Header("Ports", "Protocol"),
                [Item(Id("port7000"), "7000", "TCP"),
                 Item(Id("port8000_8010"), "8000-8010", "TCP")]
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

      class Zone < CWM::Page
        # Constructor
        #
        # @param pager [CWM::TreePager]
        def initialize(zone, _pager)
          textdomain "firewall"
          @zone = zone
          @sb = ServiceBox.new(zone)
          self.widget_id = "z:" + zone.name
        end

        # @macro seeAbstractWidget
        def label
          @zone.name
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

      private

        def tabs
          tabs = [
            ServicesTab.new(@zone),
            ServicesTab4.new(@zone),
            PortsTab2.new(@zone)
          ]
          ::CWM::Tabs.new(*tabs)
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
            firewalld.current_service_names.map { |s| [s, s] }
          end

          def init
            self.value = @zone.services
          end
        end
      end

      class Logging < CWM::Page
        # Constructor
        #
        # @param pager [CWM::TreePager]
        def initialize(_pager)
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
