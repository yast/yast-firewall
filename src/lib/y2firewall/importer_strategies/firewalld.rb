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
    # This class is reponsible of parsing firewall profile's section when
    # firewalld schema is used configuring the Y2Firewall::Firewalld instance
    # according to it.
    class Firewalld
      # [Hash] AutoYaST profile firewall's section
      attr_accessor :profile

      # Constructor
      #
      # @param [Hash] AutoYaST profile firewall's section
      def initialize(profile = {})
        @profile = profile
      end

      # It process the profile configuring the present firewalld zones
      def import
        return if profile.empty?

        profile.fetch("zones", []).each do |zone|
          process_zone(zone)
        end
      end

    private

      # Configures Y2Firewall::Firewalld::Zone that correspond with the
      # profile's firewall zone definition
      #
      # @param [Hash] AutoYaST profile firewall's section
      # @return [Boolean] true if the zone exist; nil otherwise
      def process_zone(zone_definition)
        zone = firewalld.find_zone(zone_definition["name"])

        return unless zone

        zone.services   = zone_definition["services"]   if zone_definition["services"]
        zone.interfaces = zone_definition["interfaces"] if zone_definition["interfaces"]
        zone.protocols  = zone_definition["protocols"]  if zone_definition["protocols"]
        zone.ports      = zone_definition["ports"]      if zone_definition["ports"]
        zone.masquerade = zone_definition["masquerade"] if zone_definition["masquerade"]

        true
      end

      def firewalld
        @firewalld ||= Y2Firewall::Firewalld.instance
      end
    end
  end
end
