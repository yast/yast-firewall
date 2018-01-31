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
        attr_accessor :changed
        attr_accessor :imported
        attr_accessor :enable
        attr_accessor :start
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
        self.class.enable = true if profile.fetch("enable_firewall", settings.enable_firewall)
        self.class.start = true if profile.fetch("start_firewall", false)
        importer.import(profile)
        self.class.imported = true
      end

      # Export the current firewalld configuration
      #
      # @param profile [Hash] firewall profile section to be imported
      # @return [Boolean]
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
        import(self.class.profile) unless self.class.imported
        return false unless self.class.imported

        firewalld.write
        activate_service
      end

      # Read the currnet firewalld configuration
      def read
        return false if !firewalld.installed?
        firewalld.read
      end

      # A map with the packages that needs to be installed or removed for
      # configuring properly firewalld
      #
      # @return packages [Hash] of packages to be installed or removed
      def packages
        { "install" => ["firewalld"], "remove" => [] }
      end

      def modified
        self.class.changed = true
      end

      def modified?
        self.class.changed
      end

    private

      # Depending on the profile it activate or not the firewalld service
      def activate_service
        self.class.enable ? firewalld.enable! : firewalld.disable!
        self.class.start ? firewalld.start : firewalld.stop
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
    end
  end
end
