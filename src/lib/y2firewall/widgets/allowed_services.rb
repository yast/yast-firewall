# encoding: utf-8

# Copyright (c) [2018] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require "y2firewall/firewalld"
require "y2firewall/widgets/services_table"

module Y2Firewall
  module Widgets
    # This class implements a widget which allows the user to select which services
    # should be allowed for a given zone.
    class AllowedServices < ::CWM::CustomWidget
      # Constructor
      #
      # @param zone [Y2Firewall::Firewalld::Zone] Zone
      def initialize(zone)
        textdomain "firewall"
        @zone = zone
        self.widget_id = "allowed_services"
        @available_svcs_table = ServicesTable.new(widget_id: "available:#{zone.name}")
        @allowed_svcs_table = ServicesTable.new(widget_id: "allowed:#{zone.name}")
        refresh_services
      end

      # @macro seeAbstractWidget
      def label
        _("Allowed Services")
      end

      # @macro seeCustomWidget
      def contents
        return @contents if @contents

        VBox(
          HBox(
            VBox(
              Left(Label(_("Available"))),
              available_svcs_table,
            ),
            VBox(*add_remove_buttons),
            VBox(
              Left(Label(_("Allowed"))),
              allowed_svcs_table
            )
          )
        )
      end

      # @macro seeAbstractWidget
      def handle(event)
        return unless event["ID"]

        case event["ID"]
        when :add
          add_service
        when :add_all
          add_all_services
        when :remove
          remove_service
        when :remove_all
          remove_all_services
        end
        refresh_services
        nil
      end

    private

      # @!attribute [r] available_svcs_table
      #   @return [ServicesTable]
      #
      # @!attribute [r] allowed_svcs_table
      #   @return [ServiceTable]
      #
      # @!attribute [r] zone
      #   @return [Y2Firewall::Firewalld::Zone]
      attr_reader :available_svcs_table, :allowed_svcs_table, :zone

      # Adds a service to the list of allowed ones
      def add_service
        available_svcs_table.selected_services.each { |s| zone.add_service(s) }
      end

      def add_all_services
        firewall.current_service_names.each { |s| zone.add_service(s) }
      end

      # Removes a service from the list of allowed ones
      def remove_service
        allowed_svcs_table.selected_services.each { |s| zone.remove_service(s) }
      end

      def remove_all_services
        zone.services.clone.each { |s| zone.remove_service(s) }
      end

      # Refresh the content of the services tables
      def refresh_services
        available_svcs_table.services = (firewall.current_service_names - zone.services)
        allowed_svcs_table.services = zone.services.clone
      end

      # Return a list of buttons to add/remove elements
      #
      # @return [Array<Yast::Term>] Buttons set UI terms
      def add_remove_buttons
        [
          PushButton(
            Id(:add),
            Opt(:hstretch),
            _("Add") + "#{Yast::UI.Glyph(:ArrowRight)}"
          ),
          PushButton(
            Id(:add_all),
            Opt(:hstretch),
            _("Add All") + "#{Yast::UI.Glyph(:ArrowRight)}"
          ),
          VSpacing(1),
          PushButton(
            Id(:remove),
            Opt(:hstretch),
            "#{Yast::UI.Glyph} " + _("<- Remove")
          ),
          PushButton(
            Id(:remove_all),
            Opt(:hstretch),
            "#{Yast::UI.Glyph} " + _("<- Remove All")
          )
        ]
      end

      # Return the current `Y2Firewall::Firewalld` instance
      #
      # This is just a convenience method.
      #
      # @return [Y2Firewall::Firewalld]
      def firewall
        Y2Firewall::Firewalld.instance
      end
    end
  end
end
