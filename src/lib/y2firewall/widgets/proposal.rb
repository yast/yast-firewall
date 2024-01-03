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

Yast.import "Linuxrc"

module Y2Firewall
  module Widgets
    # Custom widget for Firewall and SSH proposal responsible for disabling
    # open/close checkbox widgets when the firewall is disable
    class FirewallSSHProposal < CWM::CustomWidget
      def initialize(settings)
        super()
        @settings = settings

        @port_widgets = [Widgets::OpenSSHPort.new(@settings)]
        @port_widgets << Widgets::OpenVNCPorts.new(@settings) if Yast::Linuxrc.vnc

        @service_widgets = [
          Widgets::EnableFirewall.new(@settings, @port_widgets),
          Widgets::EnableSSHD.new(@settings)
        ]
      end

      def contents
        VBox(
          *widgets_term
        )
      end

    private

      def widgets
        @service_widgets + @port_widgets
      end

      def widgets_term
        widgets.map do |widget|
          Left(widget)
        end
      end
    end

    # Enable firewall service checkbox
    class EnableFirewall < CWM::CheckBox
      def initialize(settings, widgets)
        super()
        textdomain "firewall"
        @settings = settings
        @widgets = widgets
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

      def handle
        @widgets.map do |widget|
          checked? ? widget.enable : widget.disable
        end

        nil
      end

      def store
        checked? ? @settings.enable_firewall! : @settings.disable_firewall!
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
        super()
        textdomain "firewall"
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
        checked? ? @settings.enable_sshd! : @settings.disable_sshd!
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
        super()
        textdomain "firewall"
        @settings = settings
      end

      def init
        self.value = @settings.open_ssh
        @settings.enable_firewall ? enable : disable
      end

      def label
        _("Open SSH Port")
      end

      def opt
        [:notify]
      end

      def store
        checked? ? @settings.open_ssh! : @settings.close_ssh!
      end
    end

    # Open vnc port checkbox
    class OpenVNCPorts < CWM::CheckBox
      def initialize(settings)
        super()
        textdomain "firewall"
        @settings = settings
      end

      def init
        self.value = @settings.open_vnc

        @settings.enable_firewall ? enable : disable
      end

      def label
        _("Open &VNC Ports")
      end

      def opt
        [:notify]
      end

      def store
        checked? ? @settings.open_vnc! : @settings.close_vnc!
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
