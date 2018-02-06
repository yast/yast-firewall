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
require "y2firewall/importer"
require "y2firewall/proposal_settings"
require "installation/auto_client"

module Y2Firewall
  module Clients
    # This is a client for autoinstallation. It takes its arguments,
    # goes through the configuration and return the setting.
    # Does not do any changes to the configuration.
    class Auto < ::Installation::AutoClient
      include Yast::Logger
      class << self
        # @return [Boolean] whether the AutoYaST configuration has been
        # modified or not
        attr_accessor :changed
        # @return [Boolean] whether the AutoYaST configuration was imported
        # successfully or not
        attr_accessor :imported
        # @return [Boolean] whether the firewalld service has to be enabled
        # after writing the configuration
        attr_accessor :enable
        # @return [Boolean] whether the firewalld service has to be started
        # after writing the configuration
        attr_accessor :start
        # @return [Hash]
        attr_accessor :profile
      end

      # Constructor
      def initialize
        textdomain "firewall"
      end

      # Configuration summary
      #
      # @return [String]
      def summary
        return "" if !firewalld.installed?

        default_zone = firewalld.api.default_zone
        zones = firewalld.api.zones

        summary = "<p>"
        summary << "<b>Default ZONE:</b> #{default_zone}"
        summary << "<b>Defined zones:</b>"
        summary << "<ul>" + zones.map { |z| "<li />#{z}" }.join("\n") + "</ul>"
        summary << "</p>"

        zones.each do |zone|
          summary << zone_summary(zone)
        end

        summary
      end

      # Import the firewall configuration
      #
      # @param profile [Hash] firewall profile section to be imported
      # @return [Boolean]
      def import(profile)
        self.class.profile = profile
        return false unless read

        # Obtains the default from the control file (settings) if not present.
        enable if profile.fetch("enable_firewall", settings.enable_firewall)
        start if profile.fetch("start_firewall", false)
        importer.import(profile)
        imported
      end

      # Export the current firewalld configuration
      #
      # @return [Hash] with the current firewalld configuration
      def export
        firewalld.export
      end

      # Reset the current firewalld configuration.
      #
      # @return [Boolean]
      def reset
        importer.import({})
      end

      def change
        log.info "#{self.class}#change not implemented yet, returning :next."

        :next
      end

      # Write the imported configuration to firewalld. If for some reason the
      # configuration was not imported from the profile, it tries to import
      # it again.
      def write
        return false if !firewalld.installed?
        import(self.class.profile) unless imported?
        return false unless imported?

        firewalld.write
        activate_service
      end

      # Read the currnet firewalld configuration
      def read
        return false if !firewalld.installed?
        return true if firewalld.read?

        firewalld.read
      end

      # A map with the packages that needs to be installed or removed for
      # configuring firewalld properly
      #
      # @return packages [Hash{String => Array<String>} ] of packages to be
      # installed or removed
      def packages
        { "install" => ["firewalld"], "remove" => [] }
      end

      def modified
        self.class.changed = true
      end

      def modified?
        !!self.class.changed
      end

    private

      # Depending on the profile it activates or deactivates the firewalld
      # service
      def activate_service
        enable? ? firewalld.enable! : firewalld.disable!
        start? ? firewalld.start : firewalld.stop
      end

      # Return a firewall importer
      #
      # @return [Y2Firewall::Importer]
      def importer
        @importer ||= Importer.new
      end

      # Return a firewalld singleton instance
      #
      # @return [Y2Firewall::Firewalld] singleton instance
      def firewalld
        Firewalld.instance
      end

      # @return [Y2Firewall::ProposalSettings]
      def settings
        ProposalSettings.instance
      end

      # Set that the firewall has to be enabled when writing
      def enable
        self.class.enable = true
      end

      # Whether the firewalld service has to be enable or disable when writing
      #
      # @return [Boolean] true if has to be enabled; false otherwise
      def enable?
        !!self.class.enable
      end

      # Set that the firewall has to be started when writing
      def start
        self.class.start = true
      end

      # Whether the firewalld service has to be started or stopped when writing
      #
      # @return [Boolean] true if has to be started; false otherwise
      def start?
        !!self.class.start
      end

      # Set that the firewalld configuration has been completely imported
      def imported
        self.class.imported = true
      end

      # Whether the firewalld configuration has been already imported or not
      #
      # @return [Boolean] true if has been imported; false otherwise
      def imported?
        !!self.class.imported
      end


      FIREWALLD_ATTRS = [
        "interfaces".freeze,
        "services".freeze,
        "ports".freeze,
        "protocols".freeze
      ]
      FIREWALLD_ATTRS.each do |attr|
        define_method("#{attr}_summary") do |zone|
          status = firewalld.api.send("list_#{attr}", zone)
          return "" if status.empty?

          status.map! { |s| "<li />#{s}" }
          "<li /><b>#{attr.capitalize}:</b> " + "<ul>" + status.join("\n") + "</ul>"
        end
      end

      # Creates a summary for the given zone
      #
      # @param [String] zone name of zone
      # @return [String] HTML formated zone description
      def zone_summary(zone)
        return "" if zone.nil? || zone.empty?

        desc = ""
        FIREWALLD_ATTRS.each { |attr| desc << send("#{attr}_summary", zone) }
        return "" if desc.empty?

        summary = "<h3>#{zone}</h3>"
        summary << "<ul>#{desc}</ul>"
      end
    end
  end
end
