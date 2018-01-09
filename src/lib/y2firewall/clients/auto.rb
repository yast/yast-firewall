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
require "installation/auto_client"

module Y2Firewall
  module Clients
    # This is a client for autoinstallation. It takes its arguments,
    # goes through the configuration and return the setting.
    # Does not do any changes to the configuration.
    class Auto < ::Installation::AutoClient
      class << self
        attr_accessor :changed
      end

      def initialize
        textdomain "firewall"
      end

      def summary
        firewalld.api.list_all_zones.join("\n")
      end

      def import(profile)
        firewalld.read

        importer.import(profile)
      end

      def export
        firewalld.export
      end

      def reset
        importer.import({})
      end

      def change
        log.info "#{self.class}#change not implemented yet, returning :next."

        :next
      end

      def write
        firewalld.write
      end

      def read
        firewalld.read if firewalld.installed?
      end

      def packages
        ["firewalld"]
      end

      def modified
        self.class.changed = true
      end

      def modified?
        self.class.changed
      end

    private

      def importer
        @importer ||= ::Y2Firewall::Importer.new
      end

      def firewalld
        ::Y2Firewall::Firewalld.instance
      end
    end
  end
end
