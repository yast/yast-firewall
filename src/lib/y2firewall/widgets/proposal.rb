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
require "cwm"

module Y2Firewall
  module Widgets
    class EnableFirewall < CWM::CheckBox
      def initialize(settings)
        @settings = settings
      end

      def init
        self.value = @settings.enable_firewall
      end

      def label
        _("Enable Firewall")
      end

      def opt
        %i(notify)
      end

      def store
        value ? @settings.enable_firewall! : @settings.disable_firewall!
      end
    end

    class EnableSSHD < CWM::CheckBox
      def initialize(settings)
        @settings = settings
      end

      def init
        self.value = @settings.enable_sshd
      end

      def label
        _("Enable SSH Service")
      end

      def opt
        %i(notify)
      end

      def store
        value ? @settings.enable_sshd! : @settings.disable_sshd!
      end
    end

    class OpenSSHPort < CWM::CheckBox
      def initialize(settings)
        @settings = settings
      end

      def init
        self.value = @settings.open_ssh
      end

      def label
        _("Open SSH Port")
      end

      def opt
        %i(notify)
      end

      def store
        value ? @settings.open_ssh! : @settings.close_ssh!
      end
    end

    class OpenVNCPorts < CWM::CheckBox
      def initialize(settings)
        @settings = settings
      end

      def init
        self.value = @settings.open_vnc
      end

      def label
        _("Open &VNC Ports")
      end

      def opt
        %i(notify)
      end

      def store
        value ? @settings.open_vnc! : @settings.close_vnc!
      end
    end
  end
end
