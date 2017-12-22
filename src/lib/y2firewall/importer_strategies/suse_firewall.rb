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
    # This class is reponsible of parsing SuSEFirewall2 firewalld profile's
    # section configuring the Y2Firewall::Firewalld instance according to it.
    class SuseFirewall
      # @return [Hash] AutoYaST profile firewall's section
      attr_accessor :profile

      # SuSEFirewall2 zones
      ZONES = ["DMZ", "INT", "EXT"].freeze

      # Best effort conversion of SuSEFirewall2 services into firewalld
      # predefined ones.
      SERVICE_MAP = {
        "apache2"           => ["http"],
        "apache2-ssl"       => ["https"],
        "bind"              => ["dns"],
        "dhcp-server"       => ["dhcp"],
        "dhcp6-server"      => ["dhcpv6"],
        "nfs-client"        => ["nfs"],
        "nfs-kernel-server" => ["mountd", "nfs", "rpc-bind"],
        "netbios-server"    => ["samba"],
        "openldap"          => ["ldap", "ldaps"],
        "rsync-server"      => ["rsyncd"],
        "sshd"              => ["ssh"],
        "samba-server"      => ["samba"]
      }.freeze

      # @return [Array<string>] list of zones
      def zones
        ZONES
      end

      # Constructor
      #
      # @param [Hash] AutoYaST profile firewall's section
      def initialize(profile)
        @profile = profile
      end

      # It processes the profile configuring the firewalld zones that match
      # better with the SuSEFirewall2 ones.
      def import
        return true if profile.empty?
        zones.each { |z| process_zone(z) }
        if ipsec_trust_zone
          zone = firewalld.find_zone(zone.equivalent(ipsec_trust_zone))
          zone.services << "ipsec"
        end
        firewalld.log_denied_packets = log_denied_packets
        true
      end

    private

      # Given a SuSEFirewall2 zone name it process the profile's configuration
      # corresponding to that zone configuring the equivalent firewalld zone
      # object.
      # @param name [String] SuSEFirewall2 zone name
      def process_zone(name)
        zone = firewalld.find_zone(zone_equivalent(name))

        zone.interfaces = interfaces(name) if interfaces(name)
        zone.services   = services(name)   if services(name)
        zone.ports      = ports(name)      if ports(name)
      end

      # Obtain the services for the given SuSEFIrewall2 zone name from the
      # profile.
      #
      # @param zone_name [String]
      def services(zone_name)
        services = profile["FW_CONFIGURATIONS_#{zone_name}"]
        services ? map_services(services.split(" ")) : nil
      end

      # Obtain the interfaces for the given SuSEFIrewall2 zone name from the
      # profile.
      #
      # @param zone_name [String]
      def interfaces(zone_name)
        interfaces = profile["FW_DEV_#{zone_name}"]
        interfaces ? interfaces.split(" ") : nil
      end

      # Obtain the ports for the given SuSEFIrewall2 zone name from the
      # profile.
      #
      # @param zone_name [String]
      def ports(zone)
        return nil unless ip_ports(zone) || rpc_ports(zone) || tcp_ports(zone) || udp_ports(zone)
        [ip_ports(zone), rpc_ports(zone), tcp_ports(zone), udp_ports(zone)].compact.flatten
      end

      # Map over the given list of SuSEFIrewall2 service names converting the
      # ones that are known have changed using the corresponding firewalld
      # service name.
      #
      # @param [Array<String>] list of SuSEFirewall2 services names.
      # @return [Array<String] list of given services converted to firewalld
      # when known.
      def map_services(services)
        services.map do |service|
          SERVICE_MAP[service] || service
        end.flatten.compact.uniq
      end

      # Obtain the IP ports for the given SuSEFIrewall2 zone name from the
      # profile.
      #
      # @param zone_name [String]
      # @return [Array<Strint>, nil] list of configured IPP ports; nil if no
      # configured
      def ip_ports(zone)
        ports = profile["FW_SERVICES_#{zone}_IP"]
        ports ? ports.split(" ").map { |p| ["#{p}/udp", "#{p}/tcp"] }.flatten : nil
      end

      # Obtain the TCP ports for the given SuSEFIrewall2 zone name from the
      # profile.
      #
      # @param zone_name [String]
      # @return [Array<Strint>, nil] list of configured TCP ports; nil if no
      # configured
      def tcp_ports(zone)
        ports = profile["FW_SERVICES_#{zone}_TCP"]
        ports ? ports.split(" ").map { |p| "#{p}/tcp" } : nil
      end

      # Obtain the UDP ports for the given SuSEFIrewall2 zone name from the
      # profile.
      #
      # @param zone_name [String]
      # @return [Array<Strint>, nil] list of configured UDP ports; nil if no
      # configured
      def udp_ports(zone)
        ports = profile["FW_SERVICES_#{zone}_UDP"]
        ports ? ports.split(" ").map { |p| "#{p}/udp" } : nil
      end

      # Obtain the RPC ports for the given SuSEFIrewall2 zone name from the
      # profile.
      #
      # @param zone_name [String]
      # @return [Array<Strint>, nil] list of configured RPC ports; nil if no
      # configured
      def rpc_ports(zone)
        ports = profile["FW_SERVICES_#{zone}_RPC"]
        ports ? ports.split(" ").map { |p| ["#{p}/udp", "#{p}/tcp"] }.flatten : nil
      end

      # Given a SuSEFirewall2 zone name return the firewalld zone equivalent
      # name. It takes in account whether masquerade is enable or not.
      #
      # @param name [String] SuSEFirewall2 zone name
      # @return [String] equivalent firewalld zone name
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

      # Return whether masquerade is configured or not
      #
      # @return [Boolean] true if configured; false otherwise
      def masquerade?
        profile.fetch("FW_MASQUERADE", "no") == "yes"
      end

      # Return the ipsec trust zone name if configured or nil
      #
      # @return [Boolean] true if configured; false otherwise
      def ipsec_trust_zone
        zone_name = profile.fetch("FW_IPSEC_TRUST", "no").downcase
        return if zone_name == "no"
        return "int" if zone_name == "yes"
        zone_name
      end

      # Return which denied packets to log that match better with the
      # SuSEFirewall logging config.
      #
      # @return [String] all, unicast or none depending on the log config
      def log_denied_packets
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

      # Convenience method which return an instance of Y2Firewall::Firewalld
      #
      # @return [Y2Firewall::Firewalld] a firewalld instance
      def firewalld
        Y2Firewall::Firewalld.instance
      end
    end
  end
end
