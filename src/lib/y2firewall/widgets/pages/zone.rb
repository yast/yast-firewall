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
require "y2firewall/widgets/allowed_services"

module Y2Firewall
  module Widgets
    module Pages
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
              PortsTab.new(@zone)
            )
          )
        end
      end

      # A Tab for ports in a firewall zone
      class PortsTab < CWM::Tab
        # Constructor
        #
        # @param zone [Y2Firewall::Firewalld::Zone]
        def initialize(zone)
          textdomain "firewall"
          @zone = zone
        end

        def label
          _("Ports")
        end

        def contents
          VBox(
            # TRANSLATORS: TCP is the Transmission Control Protocol
            PortsForProtocol.new(@zone, _("TCP Ports"), :tcp),
            # TRANSLATORS: UDP is the User Datagram Protocol
            PortsForProtocol.new(@zone, _("UDP Ports"), :udp),
            # TRANSLATORS: SCTP is the Stream Control Transmission Protocol
            PortsForProtocol.new(@zone, _("SCTP Ports"), :sctp),
            # TRANSLATORS: DCCP is the Datagram Congestion Control Protocol
            PortsForProtocol.new(@zone, _("DCCP Ports"), :dccp),
            VStretch()
          )
        end

        def help
          "FIXME: ports or port ranges, separated by spaces and/or commas <br>" \
          "a port is an integer <br>" \
          "a port range is port-dash-port (with no spaces)"
        end

        def init
          log.info "INIT #{widget_id}"
        end

        def store
          log.info "STORE #{widget_id}"
        end

        # FIXME: separate objects like this do not work well with the
        # single zone.ports attribute mixing all protos. Rather make a
        # CustomWidget that handles it all
        class PortsForProtocol < CWM::InputField
          # @param proto [:tcp,:udp,:sctp,:dccp]
          def initialize(zone, label, proto)
            @zone = zone
            @proto = proto
            @label = label
            self.widget_id = "#{proto}_ports"
          end

          attr_reader :label

          def init
            log.info "INIT #{widget_id}"
            # FIXME: factor out and test
            self.value = @zone.ports
                              .map { |p| p.split("/") }
                              .find_all { |_port, proto| proto == @proto.to_s }
                              .map { |port, _proto| port }
                              .join(", ")
          end

          def store
            # FIXME: do modify immediately?
            # DUH, clumsy
            log.info "STORE #{widget_id}"
          end
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

          @allowed_services_widget = Y2Firewall::Widgets::AllowedServices.new(zone)
          self.widget_id = "st:" + zone.name
        end

        def label
          _("Services")
        end

        # @macro seeCustomWidget
        def contents
          VBox(@allowed_services_widget)
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
