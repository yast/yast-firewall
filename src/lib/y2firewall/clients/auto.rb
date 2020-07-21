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
require "y2firewall/autoyast"
require "y2firewall/proposal_settings"
require "y2firewall/summary_presenter"
require "y2firewall/dialogs/main"
require "y2firewall/autoinst_profile/firewall_section"
require "installation/auto_client"

Yast.import "Mode"
Yast.import "Stage"
Yast.import "AutoInstall"
Yast.import "AutoinstFunctions"

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
        # @return [Boolean] whether the AutoYaST configuration has been
        # modified or not
        attr_accessor :ay_config
      end

      # Constructor
      def initialize
        textdomain "firewall"
      end

      # Configuration summary
      #
      # @return [String]
      def summary
        presenter = Y2Firewall::SummaryPresenter.new(firewalld)
        return presenter.not_installed if !firewalld.installed?
        return presenter.not_configured if !firewalld.read? && !firewalld.modified?

        presenter.create
      end

      # Import the firewall configuration
      #
      # @param profile [Hash] firewall profile section to be imported
      # @return [Boolean]
      def import(profile, merge = !Yast::Mode.config)
        self.class.profile = profile
        return false if merge && !read(force: false)

        if Yast::Stage.cont
          # Configuration was already done at the end of the first stage.
          # However, we need special handling of firewall setup in case when second
          # stage is enabled and installation runs over network (ssh / vnc)
          import_second_stage
        else
          import_first_stage
        end
      end

      # Export the current firewalld configuration
      #
      # @return [Hash] with the current firewalld configuration
      def export
        autoyast.export
      end

      # Reset the current firewalld configuration.
      #
      # @return [Boolean]
      def reset
        firewalld.reset
        self.class.ay_config = false
        self.class.changed = false
      end

      def change
        read_keeping_configuration

        result = Dialogs::Main.new.run
        case result
        when :next, :finish, :ok, :accept
          self.class.ay_config = true
        end
        result
      end

      # Write the imported configuration to firewalld. If for some reason the
      # configuration was not imported from the profile, it tries to import
      # it again.
      def write
        return false if !firewalld.installed?
        import_if_needed
        return false unless imported?

        firewalld.write if firewalld.modified?

        if ay_config?
          firewalld.reset
          firewalld.read(minimal: true)
          import(self.class.profile, false)
        else
          activate_service
          # Force a reset of the API instance (bsc#1166698)
          firewalld.api = nil
        end
      end

      # Read the currnet firewalld configuration
      def read(force: true)
        return false if !firewalld.installed?
        return true if firewalld.read? && !force

        modified
        firewalld.read
      end

      # A map with the packages that needs to be installed or removed for
      # configuring firewalld properly
      #
      # @return [Hash{String => Array<String>} ] of packages to be installed or removed
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

      # Import method for the first stage.
      #
      # Except a few edge cases complete firewall configuration should be done in first
      # stage. Exceptions are installation over network (ssh / vnc) with second stage
      # enabled which requires more careful approach
      def import_first_stage
        log.info("Firewall: importing part of the profile which can be processed in first stage")
        # Obtains the default from the control file (settings) if not present.
        start_firewall_on_target if !need_second_stage_run?

        autoyast.import(self.class.profile)
        check_profile_for_errors

        imported
      end

      # Import method for the second stage
      #
      # Intended for finishing setup of exceptional cases. @see import_first_stage
      def import_second_stage
        return if !need_second_stage_run?

        log.info("Firewall: second stage finish script")

        # enable/disable firewall according to the profile. In exceptional case it
        # cannot be done in the first stage
        start_firewall_on_target
      end

      # Checks whether we need to run second stage handling
      def need_second_stage_run?
        Yast.import "Linuxrc"

        # We have a problem when
        # 1) running remote installation
        # 2) second stage was requested
        # 3) firewall was configured (somehow) and started via AY profile we can expect that
        # ssh / vnc port can be blocked.
        remote_installer = Yast::Linuxrc.usessh || Yast::Linuxrc.vnc
        second_stage_required = Yast::AutoinstFunctions.second_stage_required?
        firewall_enabled = self.class.profile.fetch("enable_firewall", settings.enable_firewall)

        remote_installer && second_stage_required && firewall_enabled
      end

      # Configures firewall service to run on target according to AY profile and product defaults
      def start_firewall_on_target
        enable if self.class.profile.fetch("enable_firewall", settings.enable_firewall)
        start if self.class.profile.fetch("start_firewall", false)
      end

      # Read the minimal configuration from firewalld, w/o dropping available configuration
      #
      # Useful to preserve the already imported, but not written yet, configuration (if any)
      def read_keeping_configuration
        return unless firewalld.installed?
        return if firewalld.read?

        self.class.profile = export
        firewalld.reset
        firewalld.read(minimal: true)
        import(self.class.profile, false)
      end

      def import_if_needed
        if ay_config?
          self.class.profile = export
          self.class.imported = false
        end

        import(self.class.profile) if self.class.profile && !imported?
      end

      def ay_config?
        !!self.class.ay_config
      end

      # Semantic AutoYaST profile check
      #
      # Problems will be stored in AutoInstall.issues_list.
      def check_profile_for_errors
        # Checking if an interface has been defined for different zones
        zones = export["zones"] || []
        all_interfaces = zones.flat_map { |zone| zone["interfaces"] || [] }
        double_entries = all_interfaces.select { |i| all_interfaces.count(i) > 1 }.uniq
        unless double_entries.empty?
          AutoInstall.issues_list.add(
            ::Installation::AutoinstIssues::InvalidValue,
            Y2Firewall::AutoinstProfile::FirewallSection.new_from_hashes(
              self.class.profile
            ),
            "interfaces",
            double_entries.join(","),
            _("This interface has been defined for more than one zone.")
          )
        end
      end

      # Depending on the profile it activates or deactivates the firewalld
      # service
      #
      # Note: it always activates the service on the target
      def activate_service
        if !Yast::Stage.initial
          enable? ? firewalld.enable! : firewalld.disable!
          start? ? firewalld.start : firewalld.stop
        else
          Yast::Execute.on_target(
            "/usr/bin/systemctl", enable? ? "enable" : "disable", "firewalld"
          )
          Yast::Execute.on_target(
            "/usr/bin/systemctl", start? ? "start" : "stop", "firewalld"
          )
        end
      end

      # Return a firewall autoyast object
      #
      # @return [Y2Firewall::Autoyast]
      def autoyast
        @autoyast ||= Autoyast.new
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
    end
  end
end
