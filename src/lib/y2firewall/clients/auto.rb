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
        attr_accessor :enable
        # @return [Boolean] whether the firewalld service has to be started
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

        firewalld.api.list_all_zones.join("\n")
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
      # configuring properly firewalld
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

      def importer
        @importer ||= ::Y2Firewall::Importer.new
      end

      def firewalld
        ::Y2Firewall::Firewalld.instance
      end

      def settings
        ProposalSettings.instance
      end

      # Whether the firewalld service has to be enable or not
      def enable
        self.class.enable = true
      end

      # Whether the firewalld service has to be enable or not
      def enable?
        !!self.class.enable
      end

      def start
        self.class.start = true
      end

      def start?
        !!self.class.start
      end

      def imported
        self.class.imported = true
      end

      # @return [Boolean] whether the configuration has been imported or not
      def imported?
        !!self.class.imported
      end
    end
  end
end
