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

Yast.import "HTML"

module Y2Firewall
  # Class for presenting the summary of the firewalld configuration in html
  # format
  class SummaryPresenter
    include Yast::Logger
    include Yast::I18n
    attr_accessor :config

    ZONE_ATTRS = ["target", "masquerade"].freeze

    # Constructor
    #
    # @note we are using the param config for be prepared in case we added
    # multiple configurations later (permanent, runtime, autoyast)
    #
    # @param config [Y2Firewall::Firewalld] instance
    def initialize(config)
      textdomain "firewall"
      @config = config
    end

    # Return the current configuration summary in html format
    #
    # @return [String] HTML summary
    def create
      # general overview
      summary = general_summary

      # per zone details
      config.zones.each do |zone|
        summary << zone_summary(zone)
      end

      summary
    end

    # Return a not configured html summary
    #
    # @return [String] HTML text
    def not_configured
      header + Yast::Summary.NotConfigured
    end

    # Return a not installed html summary
    #
    # @return [String] HTML text
    def not_installed
      header + html.Para(_("Firewalld is not available"))
    end

  private

    # Creates a piece for summary for zone detail
    #
    # See has_many (@see Y2Firewall::Firewalld::Relations#has_many) in
    # Y2Firewall::Firewalld::Zone for known detail / relations
    #
    # @param label [String] the zone attr name (used as a caption for
    #   generated blob)
    # @param attr_value [Array, Boolean, String, nil] the value of the attr to
    #   be shown
    # @return [String] A string formated using Yast::HTML methods
    def zone_detail_summary(label, attr_value)
      return "" if attr_value.nil?

      value =
        case attr_value
        when Array
          return "" if attr_value.empty?

          attr_value.join(", ")
        when TrueClass, FalseClass
          attr_value ? _("Yes") : _("No")
        else
          attr_value
        end

      Yast::HTML.Bold("#{label.capitalize}:") + " #{value}" + html.Newline
    end

    # Creates a summary for the given zone
    #
    # @param [Firewalld::Zone] zone object defining a zone
    # @return [String] HTML formated zone description
    def zone_summary(zone)
      raise ArgumentError, "zone parameter has to be defined" if zone.nil?

      zone_desc = attributes_summary(zone, zone.relations)
      return "" if zone_desc.empty?

      zone_desc = attributes_summary(zone, ZONE_ATTRS) + zone_desc

      zone_header(zone) + list(zone_desc)
    end

    def attributes_summary(zone, attributes)
      raise ArgumentError, "zone parameter has to be defined" if zone.nil?

      attributes.each_with_object([]) do |attribute, memo|
        text = zone_detail_summary(attribute, zone.public_send(attribute))
        (memo << text) unless text.empty?
        memo
      end
    end

    # Creates a general summary for firewalld
    #
    # @return [String] HTML formated firewall description
    def general_summary
      entries =
        [
          new_summary_entry(_("Default zone:"), config.default_zone),
          new_summary_entry(_("Defined zones:"), defined_zones)
        ]

      header + list(entries)
    end

    def new_summary_entry(label, entry)
      "#{bold(label)} #{entry}#{html.Newline}"
    end

    def defined_zones
      return _("No zones defined") if config.zones.empty?

      config.zones.map(&:name).join(", ")
    end

    def html
      Yast::HTML
    end

    def bold(text)
      html.Bold(text)
    end

    def header
      html.Heading("Firewall configuration")
    end

    def zone_header(zone)
      text = zone.name
      text += " (" + _("DEFAULT") + ")" if config.default_zone == zone.name
      html.Heading(text)
    end

    def list(items)
      html.List(items)
    end
  end
end
