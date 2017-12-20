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
    class Firewalld
      attr_accessor :profile

      def initialize(profile = {})
        @profile = profile
      end

      def import
        return if profile.empty?

        profile.fetch("zones", []).each do |zone|
          process_zone(zone)
        end
      end

    private

      def process_zone(zone_definition)
        zone = firewalld.find_zone(zone_definition["name"])

        return unless zone

        zone.services   = zone_definition["services"]   if zone_definition["services"]
        zone.interfaces = zone_definition["interfaces"] if zone_definition["interfaces"]
        zone.protocols  = zone_definition["protocols"]  if zone_definition["protocols"]
        zone.ports      = zone_definition["ports"]      if zone_definition["ports"]
      end

      def firewalld
        @firewalld ||= Y2Firewall::Firewalld.instance
      end
    end
  end
end
