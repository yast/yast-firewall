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
require "y2firewall/importer_strategies/suse_firewall"
require "y2firewall/importer_strategies/firewalld"

module Y2Firewall
  # This class is responsible for exporting/importing firewalld AutoYaST configuration
  # supporting the new firewalld schema but also the SuSEFirewall one (for import).
  class Autoyast
    include Yast::Logger
    # Import the given configuration
    #
    # @param profile [Hash] AutoYaST profile firewall's section
    # @return [true,nil] return true if success; return nil if the given
    #   profile is empty
    def import(profile)
      return if profile.empty?

      strategy_for(profile).new(profile).import

      true
    end

    # Return a map with current firewalld settings.
    #
    # @return [Hash] dump firewalld settings
    def export(target: :default)
      return {} unless firewalld.installed?

      {
        "enable_firewall"    => firewalld.enabled?,
        "start_firewall"     => firewalld.running?,
        "default_zone"       => firewalld.default_zone,
        "log_denied_packets" => firewalld.log_denied_packets,
        "zones"              => export_zones(target.to_s)
      }
    end

  private

    def zones_to_export(target)
      return firewalld.modified_from_default("zones") if target == "compact"

      firewalld.current_zone_names
    end

    def export_zones(target)
      zones = zones_to_export(target)

      firewalld.zones.select { |z| zones.include?(z.name) }.map { |z| export_zone(z) }
    end

    def export_zone(zone)
      (zone.attributes + zone.relations)
        .each_with_object("name" => zone.name) do |field, profile|
        profile[field.to_s] = zone.public_send(field) unless zone.public_send(field).nil?
      end
    end

    # Return an instance of Y2Firewall::Firewalld
    #
    # @return [Y2Firewall::Firewalld] a firewalld instance
    def firewalld
      Y2Firewall::Firewalld.instance
    end

    # Given a profile defines the importer stragegy to be used.
    #
    # @example Given SuSEFirewall's profile format
    #
    #   profile = { "FW_DEV_EXT" => "eth0 eth1" }
    #   importer.strategy_for(profile)            #=> Y2Firewall::ImporterStrategies::SuseFirewall
    #
    # @example Given the new firewalld profile format
    #
    #   profile =
    #     {
    #       "zones" => [
    #         { "name" => "public", "interfaces" => ["eth0", "eth1"] },
    #         { "name" => "external", "services" => ["dhcp", "dhcpv6", "ssh"] }
    #       ]
    #     }
    #
    #   importer.strategy_for(profile)            #=> Y2Firewall::ImporterStrategies::Firewalld
    #
    # @param profile [Hash] AutoYaST profile firewall's section
    # @return [ImporterStrategies::SuseFirewall,ImporterStrategies::Firewalld]
    #   the importer strategy to be used for importing.
    def strategy_for(profile)
      return ImporterStrategies::SuseFirewall if profile.any? { |k, _v| k.start_with?("FW_") }

      ImporterStrategies::Firewalld
    end
  end
end
