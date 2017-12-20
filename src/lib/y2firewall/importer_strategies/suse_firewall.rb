# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2017 SUSE LLC
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

require "y2firewall/firewalld"

module Y2Firewall
  module ImporterStrategies
    class SuseFirewall
      attr_accessor :profile

      ZONES = ["DMZ", "INT", "EXT"].freeze

      def zones
        ZONES
      end

      def initialize(profile)
        @profile = profile
      end

      def import
        return if profile.empty?

        zones.each { |z| process_zone(z) }

        if ipsec_trust_zone
          zone = firewalld.find_zone(zone.equivalent(ipsec_trust_zone))
          zone.services << "ipsec"
        end

        firewalld.log_denied_packets = logging_level
      end

      def process_zone(name)
        zone = firewalld.find_zone(zone_equivalent(name))

        zone.interfaces = interfaces(name) if interfaces(name)
        zone.services   = services(name)   if services(name)
        zone.ports      = ports(name)      if ports(name)
      end

      def services(zone)
        services = profile["FW_CONFIGURATIONS_#{zone}"]

        services ? services.split(" ") : nil
      end

      def interfaces(zone)
        interfaces = profile["FW_DEV_#{zone}"]

        interfaces ? interfaces.split(" ") : nil
      end

      def ports(zone)
        return nil unless ip_ports(zone) || rpc_ports(zone) || tcp_ports(zone) || udp_ports(zone)

        [ip_ports(zone), rpc_ports(zone), tcp_ports(zone), udp_ports(zone)].compact.flatten
      end

      def ip_ports(zone)
        ports = profile["FW_SERVICES_#{zone}_IP"]

        ports ? ports.split(" ") : nil
      end

      def tcp_ports(zone)
        ports = profile["FW_SERVICES_#{zone}_TCP"]

        ports ? ports.split(" ").map { |p| "#{p}/tcp" } : nil
      end

      def udp_ports(zone)
        ports = profile["FW_SERVICES_#{zone}_UDP"]

        ports ? ports.split(" ").map { |p| "#{p}/udp" } : nil
      end

      def rpc_ports(zone)
        ports = profile["FW_SERVICES_#{zone}_RPC"]

        ports ? ports.split(" ").map { |p| ["#{p}/udp", "#{p}/tcp"] }.flatten : nil
      end

      def zone_equivalent(name)
        case name.upcase
        when "INT"
          "trusted"
        when "EXT"
          masquerade? ? "external" : "public"
        when "DMZ"
          "dmz"
        end
      end

      def masquerade?
        profile.fetch("FW_MASQUERADE", "no") == "yes"
      end

      def ipsec_trust_zone
        zone = profile.fetch("FW_IPSEC_TRUST", "no").downcase

        return if zone == "no"
        return "int" if zone == "yes"

        zone
      end

      def logging_level
        accept_crit = profile.fetch("FW_LOG_ACCEPT_CRIT", "no") == "yes"
        drop_all = profile.fetch("FW_LOG_DROPT_ALL", "no") == "yes"
        drop_crit = profile.fetch("FW_LOG_ACCEPT_CRIT", "no") == "yes"

        if drop_all
          "all"
        elsif accept_crit || drop_crit
          "unicast"
        else
          "none"
        end
      end

    private

      def firewalld
        @firewalld ||= Y2Firewall::Firewalld.instance
      end
    end
  end
end
