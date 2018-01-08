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
    # This class is reponsible for parsing firewall profile's section when
    # firewalld schema is used configuring the Y2Firewall::Firewalld instance
    # according to it.
    class Firewalld
      # [Hash] AutoYaST profile firewall's section
      attr_reader :profile

      # Constructor
      #
      # @param [Hash] AutoYaST profile firewall's section
      def initialize(profile = {})
        @profile = profile
      end

      ATTRIBUTES = ["default_zone", "log_denied_packets"].freeze

      # It processes the profile configuring the present firewalld zones
      #
      # @return [Boolean] true if imported correctly
      def import
        return true if profile.empty?
        profile.fetch("zones", []).each do |zone|
          process_zone(zone)
        end

        ATTRIBUTES.each do |attr|
          firewalld.send("#{attr}=", profile[attr]) if profile[attr]
        end

        true
      end

    private

      ZONE_ATTRIBUTES = ["services", "interfaces", "protocols", "ports", "masquerade"].freeze

      # Configures Y2Firewall::Firewalld::Zone that correspond with the
      # profile's firewall zone definition
      #
      # @param [Hash] AutoYaST profile firewall's section
      # @return [Boolean] true if the zone exist; nil otherwise
      def process_zone(zone_definition)
        zone = firewalld.find_zone(zone_definition["name"])
        return unless zone
        ZONE_ATTRIBUTES.each do |attr|
          zone.public_send("#{attr}=", zone_definition[attr]) if zone_definition[attr]
        end
        true
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
