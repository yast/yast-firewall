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

require "yast"
require "y2firewall/firewalld"
require "ui/text_helpers"

module Y2Firewall
  module ImporterStrategies
    # This class is reponsible of parsing SuSEFirewall2 firewalld profile's
    # section configuring the Y2Firewall::Firewalld instance according to it.
    class SuseFirewall
      include Yast::Logger
      include Yast::I18n
      include UI::TextHelpers
      # @return [Hash] AutoYaST profile firewall's section
      attr_accessor :profile

      Yast.import "Report"

      # SuSEFirewall2 zones
      ZONES = ["DMZ", "INT", "EXT"].freeze

      # Best effort conversion of SuSEFirewall2 services into firewalld
      # predefined ones.
      SERVICE_MAP = {
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

      SUPPORTED_PROPERTIES = [
        "enable_firewall",
        "start_firewall",
        "FW_CONFIGURATIONS_DMZ",
        "FW_CONFIGURATIONS_EXT",
        "FW_CONFIGURATIONS_INT",
        "FW_DEV_DMZ",
        "FW_DEV_EXT",
        "FW_DEV_INT",
        "FW_SERVICES_DMZ_TCP",
        "FW_SERVICES_EXT_TCP",
        "FW_SERVICES_INT_TCP",
        "FW_SERVICES_DMZ_UDP",
        "FW_SERVICES_EXT_UDP",
        "FW_SERVICES_INT_UDP",
        "FW_SERVICES_DMZ_IP",
        "FW_SERVICES_EXT_IP",
        "FW_SERVICES_INT_IP",
        "FW_LOG_DROP_CRIT",
        "FW_LOG_DROP_ALL",
        "FW_MASQUERADE",
        "FW_PROTECT_FROM_INT"
      ].freeze

      # @return [Array<string>] list of zones
      def zones
        ZONES
      end

      # Constructor
      #
      # @param profile [Hash] AutoYaST profile firewall's section
      def initialize(profile)
        textdomain "firewall"
        @profile = profile
      end

      # Return whether some of the profile properties are not supported
      #
      # @return [Boolean] true if all the profiles properties are supported;
      # false otherwise
      def completely_supported?
        unsupported_properties.empty?
      end

      # Return the list of not supported properties that are defined in the
      # profile
      #
      # @return [Array<String>] not supported properties
      def unsupported_properties
        @profile.keys.select { |k| !SUPPORTED_PROPERTIES.include?(k) }
      end

      # It processes the profile configuring the firewalld zones that match
      # better with the SuSEFirewall2 ones.
      def import
        if profile.empty?
          log.info "The profile is empty, there is nothing to import"
          return true
        end

        completely_supported? ? warn_supported : report_unsupported

        zones.each { |z| process_zone(z) }
        if ipsec_trust_zone
          zone = firewalld.find_zone(zone.equivalent(ipsec_trust_zone))
          (zone.services << "ipsec") if zone
        end
        firewalld.log_denied_packets = log_denied_packets
        true
      end

    private

      # Convenience method for reporting a warning message to the user
      # recommending the use of firewalld schema.
      def warn_supported
        Yast::Report.Warning(
          _(
            "The profile in use is based on SuSEFirewall2 configuration.\n\n" \
            "Although all the declared properties are supported, it is recommended \n" \
            "the use of the new 'firewalld' schema. \n\n" \
            "Please, check carefully the configuration applied once the installation \n" \
            "is finished."
          )
        )
      end

      # Convenience method for reporting an error message to the user with the
      # unsupported SuSEFirewall2 properties.
      def report_unsupported
        Yast::Report.Error(
          _(
            "Unfortunately, these SuSEFirewall2 properties are not supported:\n\n%s\n\n" \
            "Check carefully the configuration applied once the installation \n" \
            "is finished."
          ) % wrap_text(unsupported_properties.join(", "))
        )
      end

      # Given a SuSEFirewall2 zone name it process the profile's configuration
      # corresponding to that zone configuring the equivalent firewalld zone
      # object.
      # @param name [String] SuSEFirewall2 zone name
      def process_zone(name)
        log.info "Processing zone #{name}"
        zone = firewalld.find_zone(zone_equivalent(name))
        if !zone
          log.error "There is no zone for #{name}"
          return
        end

        if interfaces(name)
          zone.interfaces = interfaces(name)
          firewalld.default_zone = zone_equivalent(name) if default_zone?(name)
        end

        zone.services   = services(name)   if services(name)
        zone.protocols  = protocols(name)  if protocols(name)
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
      # profile. It removes 'any' from the list of interfaces as it is an
      # especial case for SuSEFirewall2.
      #
      # @param zone_name [String]
      # @return [Array<String>, nil] return the list of interfaces without
      # especial wildcards like 'any' or nil in case the key is not defined
      def interfaces(zone_name)
        interfaces = profile["FW_DEV_#{zone_name}"]
        interfaces ? interfaces.split(" ").reject { |i| i == "any" } : nil
      end

      # Return whether the given zone name is the default one.
      #
      # @param zone_name [String]
      # @return [Boolean] true if the zone name is the default one; false
      # otherwise
      def default_zone?(zone_name)
        profile.fetch("FW_DEV_#{zone_name}", []).include?("any")
      end

      # Obtain the protocols for the given SuSEFIrewall2 zone name from the
      # profile.
      #
      # @param zone [String]
      # @return [Array<String>, nil]
      def protocols(zone)
        protocols = profile["FW_SERVICES_#{zone}_IP"]
        protocols ? protocols.split(" ") : nil
      end

      # Obtain the ports for the given SuSEFIrewall2 zone name from the
      # profile.
      #
      # @param zone [String]
      # @return [Array<String>, nil]
      def ports(zone)
        return nil unless rpc_ports(zone) || tcp_ports(zone) || udp_ports(zone)
        [rpc_ports(zone), tcp_ports(zone), udp_ports(zone)].compact.flatten
      end

      # Map over the given list of SuSEFIrewall2 service names converting the
      # ones that are known have changed using the corresponding firewalld
      # service name.
      #
      # @param services [Array<String>] list of SuSEFirewall2 services names.
      # @return [Array<String>] list of given services converted to firewalld
      # when known.
      def map_services(services)
        services.map do |service|
          SERVICE_MAP[service] || service
        end.flatten.compact.uniq
      end

      # Obtain the TCP ports for the given SuSEFIrewall2 zone name from the
      # profile.
      #
      # @param zone [String]
      # @return [Array<Strint>, nil] list of configured TCP ports; nil if no
      # configured
      def tcp_ports(zone)
        ports = profile["FW_SERVICES_#{zone}_TCP"]
        ports ? ports.split(" ").map { |p| "#{p.sub(":", "-")}/tcp" } : nil
      end

      # Obtain the UDP ports for the given SuSEFIrewall2 zone name from the
      # profile.
      #
      # @param zone [String]
      # @return [Array<Strint>, nil] list of configured UDP ports; nil if no
      # configured
      def udp_ports(zone)
        ports = profile["FW_SERVICES_#{zone}_UDP"]
        ports ? ports.split(" ").map { |p| "#{p.sub(":", "-")}/udp" } : nil
      end

      # Obtain the RPC ports for the given SuSEFIrewall2 zone name from the
      # profile.
      #
      # @param zone [String]
      # @return [Array<String>, nil] list of configured RPC ports; nil if no
      #   configured
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
          trusted? ? "trusted" : "internal"
        when "EXT"
          masquerade? ? "external" : "public"
        when "DMZ"
          "dmz"
        end
      end

      # Return whether internal network is trusted or not
      #
      # @return [Boolean] true if trusted; false otherwise
      def trusted?
        profile.fetch("FW_PROTECT_FROM_INT", "no") == "no"
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
      # @return [String] all, unicast or off depending on the log config
      def log_denied_packets
        return "all" if profile.fetch("FW_LOG_DROP_ALL", "no") == "yes"
        return "unicast" if profile.fetch("FW_LOG_DROP_CRIT", "no") == "yes"

        "off"
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
