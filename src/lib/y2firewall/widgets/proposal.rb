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
    # Enable firewall service checkbox
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
        [:notify]
      end

      def store
        value ? @settings.enable_firewall! : @settings.disable_firewall!
      end

      def help
        _(
          "<p><b><big>Firewall and SSH</big></b><br>\n" \
            "Firewall is a defensive mechanism that protects " \
            "your computer from network attacks.\n" \
            "SSH is a service that allows logging into this " \
            "computer remotely via dedicated\n" \
            "SSH client</p>"
        ) +
          _(
            "<p>Here you can choose whether the firewall will be " \
            "enabled or disabled after\nthe installation. It is " \
            "recommended to keep it enabled.</p>"
          )
      end
    end

    # Enable sshd service checkbox
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
        [:notify]
      end

      def store
        value ? @settings.enable_sshd! : @settings.disable_sshd!
      end

      def help
        _(
          "<p>With enabled firewall, you can decide whether to open " \
          "firewall port for SSH\n service and allow remote SSH logins. " \
          "Independently you can also enable SSH service (i.e. it\n" \
          "will be started on computer boot).</p>"
        )
      end
    end

    # Open ssh port checkbox
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
        [:notify]
      end

      def store
        value ? @settings.open_ssh! : @settings.close_ssh!
      end
    end

    # Open vnc port checkbox
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
        [:notify]
      end

      def store
        value ? @settings.open_vnc! : @settings.close_vnc!
      end

      def help
        _(
          "<p>You can also open VNC ports in firewall. It will not enable\n" \
            "the remote administration service on a running system but it is\n" \
            "started by the installer automatically if needed.</p>"
        )
      end
    end
  end
end
