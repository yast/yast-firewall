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
require "cwm/common_widgets"
require "cwm/page"
require "cwm/table"
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
          Yast.import "Popup"
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
            PortsForProtocols.new(@zone),
            VStretch()
          )
        end

        # A group of InputFields to specify the open TCP, UDP, SCTP and DCCP ports.
        class PortsForProtocols < CWM::CustomWidget
          extend Yast::I18n

          PROTOCOLS = {
            # TRANSLATORS: TCP is the Transmission Control Protocol
            tcp:  N_("TCP Ports"),
            # TRANSLATORS: UDP is the User Datagram Protocol
            udp:  N_("UDP Ports"),
            # TRANSLATORS: SCTP is the Stream Control Transmission Protocol
            sctp: N_("SCTP Ports"),
            # TRANSLATORS: DCCP is the Datagram Congestion Control Protocol
            dccp: N_("DCCP Ports")
          }.freeze

          def initialize(zone)
            textdomain "firewall"
            @zone = zone
          end

          def contents
            fields = PROTOCOLS.map do |proto_sym, label|
              InputField(Id(proto_sym), Opt(:hstretch), _(label))
            end
            VBox(* fields)
          end

          def valid_port_description
            format(
              _("Enter ports or port ranges, separated by spaces and/or commas.\n" \
                "A port is an integer.\n" \
                "A port range is port-dash-port (with no spaces).\n" \
                "For example:\n" \
                "%s"),
              "16001-16009, 18080"
            )
          end

          def help
            valid_port_description.gsub("\n", "<br>\n")
          end

          def init
            by_proto = ports_from_array(@zone.ports)
            PROTOCOLS.each do |proto_sym, _label|
              s = by_proto.fetch(proto_sym, []).join(", ")
              Yast::UI.ChangeWidget(Id(proto_sym), :Value, s)
            end
          end

          def store
            @zone.ports = ports_to_array(values_by_proto.to_h)
          end

          def validate
            values_by_proto.each do |proto_sym, ranges|
              invalid_range = ranges.find { |r| !valid_range?(r) }
              next unless invalid_range
              Yast::UI.SetFocus(Id(proto_sym))
              err_msg = format(_("Invalid port range: %s"), invalid_range)
              Yast::Popup.Error(err_msg + "\n" + valid_port_description)
              return false
            end
            true
          end

        private

          # @return [Hash{Symbol => Array<String>}]
          def values_by_proto
            PROTOCOLS.map do |proto_sym, _label|
              line = Yast::UI.QueryWidget(Id(proto_sym), :Value)
              [proto_sym, items_from_ui(line)]
            end
          end

          def valid_range?(r)
            r =~ /\d+/ || r =~ /\d+-\d+/
          end

          def items_from_ui(s)
            # the separator is at least one comma or space, surrounded by optional spaces
            s.split(/ *[, ] */)
          end

          # @param hash [Hash{Symbol => Array<String>}] ports specification
          #   categorized by protocol
          # @return [Array] ports specification
          #   as array for {Y2Firewall::Firewalld::Zone#ports}
          # @example
          #   h = { tcp: ["55555-55666", "44444"], udp: ["33333"] }
          #   a = ["55555-55666/tcp", "44444/tcp", "33333/udp"]
          #   ports_to_array(h) # => a
          def ports_to_array(hash)
            hash.map { |sym, ports| ports.map { |p| "#{p}/#{sym}" } }.flatten
          end

          # @param a [Array] ports specification
          #   as array from {Y2Firewall::Firewalld::Zone#ports}
          # @return [Hash{Symbol => Array<String>}] ports specification
          #   categorized by protocol
          # @example
          #   a = ["55555-55666/tcp", "44444/tcp", "33333/udp"]
          #   h = { tcp: ["55555-55666", "44444"], udp: ["33333"] }
          #   ports_from_array(a) # => h
          def ports_from_array(a)
            a
              .map { |p| p.split("/") }
              .each_with_object({}) do |i, acc|
                ports, proto = *i
                proto = proto.to_sym
                acc[proto] ||= []
                acc[proto] << ports
              end
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
      end
    end
  end
end
