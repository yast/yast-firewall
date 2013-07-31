# encoding: utf-8

# ***************************************************************************
#
# Copyright (c) 2000 - 2012 Novell, Inc.
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#
# ***************************************************************************
#
# File:	include/firewall/helps.ycp
# Package:	Firewall configuration
# Summary:	Firewall dialogs helps
# Authors:	Lukas Ocilka <locilka@suse.cz>
#
# $Id$
#
# File includes helps for yast2-firewall dialogs.
module Yast
  module FirewallHelpsInclude
    def initialize_firewall_helps(include_target)
      textdomain "firewall"
      #import "NetworkService";
      Yast.import "SuSEFirewall"

      @HELPS = {
        # TRANSLATORS: Read dialog help
        "reading_configuration"          => _(
          "<p><b><big>Reading Firewall Configuration</big></b>\n<br>Please wait...</p>"
        ),
        # TRANSLATORS: Write dialog help
        "saving_configuration"           => _(
          "<p><b><big>Saving Firewall Configuration</big></b>\n<br>Please wait...</p>"
        ),
        # TRANSLATORS: Firewall interfaces dialog help
        "firewall-interfaces"            => _(
          "<p><b><big>Interfaces</big></b>\n" +
            "<br>Here, assign your network devices into firewall zones\n" +
            "by selecting the device in the table and clicking <b>Change</b>.</p>\n" +
            "\n" +
            "<p>Enter special strings, like <tt>any</tt>, using \n" +
            "<b>Custom</b>. You can also enter interfaces not yet configured here.\n" +
            "If you need masquerading, the string <tt>any</tt> is not allowed.</p>\n" +
            "\n" +
            "<p>Every network device should be assigned to a firewall zone.\n" +
            "Network traffic through any unassigned interface is blocked.</p>\n"
        ),
        # Network Manager
        #(NetworkService::IsManaged() ?
        #    // TRANSLATORS: Optional help text for Firewall interfaces
        #    //              Used only when the network interfaces are handled by the Network Manager tool
        #    //              %1 is a string 'any' (by default)
        #    //              %2 is a zone name 'External Zone' (by default)
        #    sformat(_("<p>You are currently using NetworkManager to control your
        #network interfaces. You should insert a string '%1' into the zone '%2' using
        #<b>Custom</b>. Otherwise your configuration might not work.
        #</p>"), SuSEFirewall::special_all_interface_string, SuSEFirewall::GetZoneFullName(SuSEFirewall::special_all_interface_zone)):""
        #),

        # TRANSLATORS: Allowed services dialog help 1/2
        "allowed-services"               => _(
          "<p><b><big>Allowed Services</big></b>\n" +
            "<br>Specify services or ports that should be accessible from the network.\n" +
            "Networks are divided into firewall zones.</p>\n" +
            "\n" +
            "<p>To allow a service, select the <b>Zone</b> and the\n" +
            "<b>Service to Allow</b> then press <b>Add</b>.\n" +
            "To remove an allowed service, select the <b>Zone</b> and the <b>Allowed Service</b> then press <b>Delete</b>.</p>\n" +
            "\n" +
            "<p>By deselecting <b>Protect Firewall from Internal Zone</b>, you remove\n" +
            "protection from the zone. All services and ports in your internal network will\n" +
            "be unprotected.</p>\n"
        ) +
          # TRANSLATORS: Allowed services dialog help 2/2
          _(
            "<p>Additional settings can be configured using <b>Advanced</b>.\n" +
              "Entries must be separated by a space. There you can allow TCP, UDP, and RPC ports and\n" +
              "IP protocols.</p>\n" +
              "<p>TCP and UDP ports can be entered as port names (<tt>ftp-data</tt>),\n" +
              "port numbers (<tt>3128</tt>), and port ranges (<tt>8000:8520</tt>).\n" +
              "RPC ports must be entered as service names (<tt>portmap</tt> or <tt>nlockmgr</tt>).\n" +
              "Enter IP protocols as the protocol name (<tt>esp</tt>).\n" +
              "</p>\n"
          ),
        # TRANSLATORS: Base masquerade dialog help
        "base-masquerading"              => _(
          "<p><b><big>Masquerading</big></b>\n" +
            "<br>Masquerading is a function that hides your internal network behind your firewall and allows\n" +
            "your internal network to access the external network, such as the Internet, transparently. Requests\n" +
            "from the external network to the internal one are blocked.\n" +
            "Select <b>Masquerade Networks</b> to masquerade your networks\n" +
            "to the external network.</p>\n"
        ),
        # TRANSLATORS: Redirect-masquerade table dialog help
        "masquerade-redirect-table"      => _(
          "<p>\n" +
            "Although requests from the external network cannot reach your internal network, it is possible to\n" +
            "transparently redirect any requested ports on your firewall to any internal IP.  \n" +
            "To add a new redirect rule, press <b>Add</b> and complete the redirect form.</p>\n" +
            "\n" +
            "<p>To removed any redirect rule, select it in the table and press <b>Delete</b>.</p>\n"
        ),
        # TRANSLATORS: Simple broadcast configuration dialog help
        "simple-broadcast-configuration" => _(
          "<p><b><big>Broadcast Configuration</big></b>\n" +
            "<br>Broadcast packets are special UDP packets sent to the whole network to find \n" +
            "neighboring computers or send information to each computer in the network.\n" +
            "For example, CUPS servers provide information about their printing queues using broadcast packets.</p>\n" +
            "\n" +
            "<p>SuSEfirewall2 services selected in allowed interfaces automatically add needed broadcast\n" +
            "ports here. To remove any or add any others, edit lists of space-separated ports for\n" +
            "particular zones.</p>\n" +
            "\n" +
            "<p>Other dropped broadcast packets are logged. It could be quite a lot of packets in wider networks.\n" +
            "To suppress logging of these packets, deselect <b>Log Not Accepted Broadcast Packets</b>\n" +
            "for the desired zones.</p>\n"
        ),
        "broadcast-reply"                => _(
          "<p><b><big>Broadcast Reply</big></b><br>\n" +
            "Firewall usually drops packets that are sent by another machines as their reply\n" +
            "to broadcast packets sent by your system, e.g., Samba browsing or SLP browsing.</p>\n" +
            "\n" +
            "<p>Here you can configure which packets are allowed to pass through the firewall. Use <b>Add</b>\n" +
            "button to add a new rule. You will have to choose the firewall zone and also choose from\n" +
            "some already defined services or set your rule completely manually.</p>\n"
        ),
        # TRANSLATORS: Base IPsec configuration dialog help
        "base-ipsec-support"             => _(
          "<p><b><big>IPsec Support</big></b>\n" +
            "<br>IPsec is an encrypted communication between trusted hosts or networks through untrusted networks, such as\n" +
            "the Internet. This dialog opens IPsec for an external zone using\n" +
            "<b>Enabled</b>.</p>\n" +
            "\n" +
            "<p><b>Details</b> configures how to handle successfully decrypted\n" +
            "IPsec packets.  For example, they could be handled as if they were from the internal zone.</p>\n"
        ),
        # TRANSLATORS: Base Logging configuration dialog help
        "base-logging"                   => _(
          "<p><b><big>Logging Level</big></b>\n" +
            "<br>This is a base configuration dialog for IP packet logging settings. Here,\n" +
            "configure logging for incoming connection packets. Outgoing ones are not logged at all.</p>\n" +
            "\n" +
            "<p>There are two groups of logged IP packets: <b>Accepted Packets</b> and <b>Not Accepted Packets</b>.\n" +
            "You can choose from three levels of logging for each group: <b>Log All</b> for logging every\n" +
            "packet, <b>Log Only Critical</b> for logging only interesting ones, or <b>Do Not Log Any</b>\n" +
            "for no logging. You should log at least critical accepted packets.</p>\n"
        ),
        # TRANSLATORS: Base Summary dialog help
        "box-summary"                    => _(
          "<p><b><big>Summary</big></b>\n" +
            "<br>Here, find a summary of your configuration settings.\n" +
            "This summary is divided into general configuration and parts for each firewall zone.\n" +
            "Every existing zone is summarized here.</p>\n" +
            "\n" +
            "<p><b>Firewall Starting</b> shows whether the firewall is started in the\n" +
            "<b>boot process</b> or only <b>manually</b>.</p>\n" +
            "\n" +
            "<p>Firewall zones must have a network interface assigned to list the following items in the summary:</p>\n" +
            "\n" +
            "<p><b>Interfaces</b>: All interfaces are listed using their configuration name and device name.</p>\n" +
            "\n" +
            "<p><b>Open Services, Ports, and Protocols</b>: This lists all allowed network services, additional\n" +
            "TCP (Transmission Control Protocol), UDP (User Datagram Protocol), and RPC (Remote Procedure Call)\n" +
            "ports, and IP (Internet Protocol) protocols.</p>\n"
        ),
        # TRANSLATORS: Additional Services dialog help 1/6
        "additional-services"            => _(
          "<p>Here, enter additional\nports or protocols to enable in the firewall zone.</p>"
        ) +
          # TRANSLATORS: Additional Services dialog help 2/6
          # please, do not modify examples
          _(
            "<p><b>TCP Ports</b> and <b>UDP Ports</b> can be entered as\n" +
              "a list of port numbers, port names, or port ranges separated by spaces,\n" +
              "such as <tt>22</tt>, <tt>http</tt>, or <tt>137:139</tt>.</p>"
          ) +
          # TRANSLATORS: Additional Services dialog help 3/6
          # please, do not modify examples
          _(
            "<p><b>RPC Ports</b> is a list of RPC services, such as\n<tt>nlockmgr</tt>, <tt>ypbind</tt>, or <tt>portmap</tt>, separated by spaces.</p>"
          ) +
          # TRANSLATORS: Additional Services dialog help 4/6
          # please, do not modify examples
          _(
            "<p><b>IP Protocols</b> is a list of protocols, such as\n" +
              "<tt>esp</tt>, <tt>smp</tt>, or <tt>chaos</tt>, separated by spaces.\n" +
              "Find the current list of protocols at\n" +
              "http://www.iana.org/assignments/protocol-numbers.</p>"
          ) +
          # TRANSLATORS: Additional Services dialog help 5/6
          # please, do not modify examples
          _(
            "<p>The <b>Port Range</b> consists of two colon-separated numbers that represent\n" +
              "all numbers inside the range including the numbers themselves.\n" +
              "The first port number must be lower than the second one,\n" +
              "for example, <tt>200:215</tt>.</p>"
          ) +
          # TRANSLATORS: Additional Services dialog help 6/6
          _(
            "<p>The <b>Port Name</b> is a name assigned to a port number by the IANA\n" +
              "organization. One port number can have multiple port names assigned. Find\n" +
              "the assignment currently in use in the <tt>/etc/services</tt> file.</p>"
          ),
        # TRANSLATORS: help for Installation Proposal Dialog
        "installation_proposal"          => _(
          "<p><b><big>Firewall</big></b><br />\nA firewall is a defensive mechanism that protects your computer from network attacks.</p>\n"
        ),
        # TRANSLATORS: general help for Custom Rules 1/5
        "custom-rules"                   => _(
          "<p><b><big>Custom Rules</big></b><br>\n" +
            "Set special firewall rules that allow new connections\n" +
            "matching these rules.</p>\n"
        ) +
          # TRANSLATORS: general help for Custom Rules 2/5
          _(
            "<p><b>Source Network</b><br>\n" +
              "Network or IP address where the connection comes from,\n" +
              "e.g., <tt>192.168.0.1</tt> or <tt>192.168.0.0/255.255.255.0</tt>\n" +
              "or <tt>192.168.0.0/24</tt> or <tt>0/0</tt> (which means <tt>all</tt>).</p>\n"
          ) +
          # TRANSLATORS: general help for Custom Rules 3/5
          _(
            "<p><b>Protocol</b><br>\n" +
              "Protocol used by that packet. Special protocol <tt>RPC</tt> is used for\n" +
              "RPC services.</p>"
          ) +
          # TRANSLATORS: general help for Custom Rules 4/5
          _(
            "<p><b>Destination Port</b><br>\n" +
              "Port name, port number or range of ports that are allowed to be\n" +
              "accessed, e.g., <tt>smtp</tt> or <tt>25</tt> or <tt>100:110</tt>.\n" +
              "In case of <tt>RPC</tt> protocol, use the RPC service name.\n" +
              "This entry is optional.</p>"
          ) +
          # TRANSLATORS: general help for Custom Rules 5/5
          _(
            "<p><b>Source Port</b><br>\n" +
              "Port name, port number or range of ports where the packet\n" +
              "originates from. This entry is optional.</p>"
          ),
        # TRANSLATORS: help for Custom Rules - Adding new rule 1/4
        "custom-rules-popup"             => _(
          "<p><b>Source Network</b><br>\n" +
            "Network or IP address where the connection comes from,\n" +
            "e.g., <tt>192.168.0.1</tt> or <tt>192.168.0.0/255.255.255.0</tt>\n" +
            "or <tt>192.168.0.0/24</tt> or <tt>0/0</tt> (which means <tt>all</tt>).</p>\n"
        ) +
          # TRANSLATORS: help for Custom Rules - Adding new rule 2/4
          _(
            "<p><b>Protocol</b><br>\n" +
              "Protocol used by that packet. Special protocol <tt>RPC</tt> is used for\n" +
              "RPC services.</p>"
          ) +
          # TRANSLATORS: help for Custom Rules - Adding new rule 3/4
          _(
            "<p><b>Destination Port</b><br>\n" +
              "Port name, port number or range of ports that are allowed to be\n" +
              "accessed, e.g., <tt>smtp</tt> or <tt>25</tt> or <tt>100:110</tt>.\n" +
              "In case of <tt>RPC</tt> protocol, use the RPC service name.\n" +
              "This entry is optional.</p>"
          ) +
          # TRANSLATORS: help for Custom Rules - Adding new rule 4/4
          _(
            "<p><b>Source Port</b><br>\n" +
              "Port name, port number or range of ports where the packet\n" +
              "originates from. This entry is optional.</p>"
          )
      }
    end

    def HelpForDialog(identification)
      Ops.get(
        @HELPS,
        identification,
        Builtins.sformat(_("FIXME: Help for '%1' is missing!"), identification)
      )
    end
  end
end
