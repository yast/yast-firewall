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
# File:	modules/SuSEFirewallCMDLine.ycp
# Package:	Firewall configuration
# Summary:	Command Line for YaST2 Firewall (Only for Firewall)
# Authors:	Lukas Ocilka <locilka@suse.cz>
# Internal
#
# $Id$
require "yast"
require "network/susefirewalld"

module Yast
  class SuSEFirewallCMDLineClass < Module
    def main
      Yast.import "UI"

      textdomain "firewall"

      Yast.import "CommandLine"
      Yast.import "SuSEFirewall"
      Yast.import "SuSEFirewallServices"
      Yast.import "SuSEFirewallUI"
      Yast.import "Mode"
      Yast.import "Report"
      Yast.import "String"

      Yast.include self, "firewall/summary.rb"
      Yast.include self, "firewall/generalfunctions.rb"

      @cmdline = {
        "id"         => "firewall",
        # TRANSLATORS: CommandLine help
        "help"       => _(
          "Firewall configuration"
        ),
        "initialize" => fun_ref(SuSEFirewall.method(:Read), "boolean ()"),
        "finish"     => fun_ref(SuSEFirewall.method(:Write), "boolean ()"),
        "actions"    => {
          "startup"      => {
            "handler" => fun_ref(method(:FWCMDStartup), "boolean (map)"),
            # TRANSLATORS: CommandLine help
            "help"    => _("Start-up settings"),
            "example" => ["startup show", "startup atboot", "startup manual"]
          },
          "zones"        => {
            "handler" => fun_ref(method(:FWCMDZones), "boolean (map)"),
            # TRANSLATORS: CommandLine help
            "help"    => _(
              "Known firewall zones"
            ),
            "example" => "zones list"
          },
          "interfaces"   => {
            "handler" => fun_ref(method(:FWCMDInterfaces), "boolean (map)"),
            # TRANSLATORS: CommandLine help
            "help"    => _(
              "Network interfaces configuration"
            ),
            "example" => [
              "interfaces show",
              "interfaces add interface=eth0 zone=INT"
            ]
          },
          "services"     => {
            "handler" => fun_ref(method(:FWCMDServices), "boolean (map)"),
            # TRANSLATORS: CommandLine help
            "help"    => _(
              "Allowed services, ports, and protocols"
            ),
            "example" => [
              "services show detailed",
              "services set protect=yes zone=INT",
              "services add service=service:dhcp-server zone=EXT",
              "services remove ipprotocol=esp tcpport=12,13,ipp zone=DMZ"
            ]
          },
          "broadcast"    => {
            "handler" => fun_ref(method(:FWCMDBroadcast), "boolean (map)"),
            # TRANSLATORS: CommandLine help
            "help"    => _(
              "Broadcast packet settings"
            ),
            "example" => "broadcast add zone=INT port=ipp,233"
          },
          "masquerade"   => {
            "handler" => fun_ref(method(:FWCMDMasquerade), "boolean (map)"),
            # TRANSLATORS: CommandLine
            "help"    => _("Masquerading settings"),
            "example" => ["masquerade show", "masquerade enable"]
          },
          "masqredirect" => {
            "handler" => fun_ref(method(:FWCMDMasqRedirect), "boolean (map)"),
            # TRANSLATORS: CommandLine help
            "help"    => _(
              "Redirect requests to masqueraded IP"
            ),
            "example" => "masqredirect remove record=6"
          },
          "logging"      => {
            "handler" => fun_ref(method(:FWCMDLogging), "boolean (map)"),
            # TRANSLATORS: CommandLine help
            "help"    => _("Logging settings"),
            "example" => [
              "logging set accepted=critical",
              "logging set logbroadcast=no zone=INT"
            ]
          },
          "summary"      => {
            "handler" => fun_ref(method(:FWCMDSummary), "boolean (map)"),
            # TRANSLATORS: CommandLine help
            "help"    => _(
              "Firewall configuration summary"
            ),
            "example" => ["summary", "summary zone=EXT"]
          },
          "enable"       => {
            "handler" => fun_ref(method(:FWCMDEnable), "boolean (map)"),
            # TRANSLATORS: CommandLine help
            "help"    => _("Enables firewall"),
            "example" => ["enable"]
          },
          "disable"      => {
            "handler" => fun_ref(method(:FWCMDDisable), "boolean (map)"),
            # TRANSLATORS: CommandLine help
            "help"    => _("Disables firewall"),
            "example" => ["disable"]
          }
        },
        "options"    => {
          "show"         => {
            # TRANSLATORS: CommandLine help
            "help" => _("Show current settings")
          },
          "atboot"       => {
            # TRANSLATORS: CommandLine help
            "help" => _(
              "Start firewall in the boot process"
            )
          },
          "manual"       => {
            # TRANSLATORS: CommandLine help
            "help" => _(
              "Start firewall manually"
            )
          },
          "list"         => {
            # TRANSLATORS: CommandLine help
            "help" => _(
              "List configured entries"
            )
          },
          "zone"         => {
            "type" => "string",
            # TRANSLATORS: CommandLine help
            "help" => _("Zone short name")
          },
          "add"          => {
            # TRANSLATORS: CommandLine help
            "help" => _("Add a new record")
          },
          "remove"       => {
            # TRANSLATORS: CommandLine help
            "help" => _("Remove a record")
          },
          "interface"    => {
            "type" => "string",
            # TRANSLATORS: CommandLine help
            "help" => _(
              "Network interface configuration name"
            )
          },
          "accepted"     => {
            "type" => "string",
            # TRANSLATORS: CommandLine help
            "help" => _(
              "Logging accepted packets (all|crit|none)"
            )
          },
          "nonaccepted"  => {
            "type" => "string",
            # TRANSLATORS: CommandLine help
            "help" => _(
              "Logging not accepted packets (all|crit|none)"
            )
          },
          "logbroadcast" => {
            "type" => "string",
            # TRANSLATORS: CommandLine help
            "help" => _(
              "Logging broadcast packets (yes|no)"
            )
          },
          "set"          => {
            # TRANSLATORS: CommandLine help
            "help" => _("Set value")
          },
          "port"         => {
            "type" => "string",
            # TRANSLATORS: CommandLine help
            "help" => _(
              "Port name or number; comma-separate multiple ports"
            )
          },
          "service"      => {
            "type" => "string",
            # TRANSLATORS: CommandLine help
            "help" => _(
              "Known firewall service; comma-separate multiple services"
            )
          },
          "tcpport"      => {
            "type" => "string",
            # TRANSLATORS: CommandLine help
            "help" => _(
              "TCP port name or number; comma-separate multiple ports"
            )
          },
          "udpport"      => {
            "type" => "string",
            # TRANSLATORS: CommandLine help
            "help" => _(
              "UDP port name or number; comma-separate multiple ports"
            )
          },
          "rpcport"      => {
            "type" => "string",
            # TRANSLATORS: CommandLine help
            "help" => _(
              "RPC port name; comma-separate multiple ports"
            )
          },
          "ipprotocol"   => {
            "type" => "string",
            # TRANSLATORS: CommandLine help
            "help" => _(
              "IP protocol name; comma-separate multiple protocols"
            )
          },
          "protect"      => {
            "type" => "string",
            # TRANSLATORS: CommandLine help
            "help" => _(
              "Set zone protection (yes|no)"
            )
          },
          "detailed"     => {
            # TRANSLATORS: CommandLine help
            "help" => _("Detailed information")
          },
          "enable"       => {
            # TRANSLATORS: CommandLine help
            "help" => _("Enable option")
          },
          "disable"      => {
            # TRANSLATORS: CommandLine help
            "help" => _("Disable option")
          },
          "sourcenet"    => {
            "type" => "string",
            # TRANSLATORS: CommandLine help
            "help" => _(
              "Source network, such as 0/0 or 145.12.35.0/255.255.255.0"
            )
          },
          "protocol"     => {
            "type" => "string",
            # TRANSLATORS: CommandLine help
            "help" => _("Protocol (tcp|udp)")
          },
          "req_ip"       => {
            "type" => "string",
            # TRANSLATORS: CommandLine help
            "help" => _(
              "Requested external IP (optional)"
            )
          },
          "req_port"     => {
            "type" => "string",
            # TRANSLATORS: CommandLine help
            "help" => _(
              "Requested port name or number"
            )
          },
          "redir_ip"     => {
            "type" => "string",
            # TRANSLATORS: CommandLine help
            "help" => _(
              "Redirect to internal IP"
            )
          },
          "redir_port"   => {
            "type" => "string",
            # TRANSLATORS: CommandLine help
            "help" => _(
              "Redirect to port on internal IP (optional)"
            )
          },
          "record"       => {
            "type" => "integer",
            # TRANSLATORS: CommandLine help
            "help" => _("Record number")
          },
          "names"        => {
            # TRANSLATORS: CommandLine help
            "help" => _(
              "Use port names instead of port numbers"
            )
          }
        },
        "mappings"   => {
          "startup"      => ["show", "atboot", "manual"],
          "zones"        => ["list"],
          "interfaces"   => ["show", "add", "remove", "interface", "zone"],
          "services"     => [
            "list",
            "show",
            "add",
            "remove",
            "set",
            "detailed",
            "zone",
            "service",
            "tcpport",
            "udpport",
            "rpcport",
            "ipprotocol",
            "protect"
          ],
          "masquerade"   => ["show", "enable", "disable"],
          "masqredirect" => [
            "show",
            "add",
            "remove",
            "sourcenet",
            "protocol",
            "req_ip",
            "req_port",
            "redir_ip",
            "redir_port",
            "record",
            "names"
          ],
          "logging"      => [
            "show",
            "set",
            "accepted",
            "nonaccepted",
            "logbroadcast",
            "zone"
          ],
          "broadcast"    => ["show", "add", "remove", "zone", "port"],
          "summary"      => ["zone"],
          "enable"       => [],
          "disable"      => []
        }
      }

      ConfigureFirewalld()

    end

    # Returns list of strings made from the comma-separated string got as param.
    #
    # @param [Object] comma_separated_string
    # @return [Array<String>] items
    def CommaSeparatedList(comma_separated_string)
      comma_separated_string = deep_copy(comma_separated_string)
      Builtins.splitstring(Convert.to_string(comma_separated_string), ",")
    end

    # Function checks zone string for existency
    #
    # @param [String] zone
    # @param [Boolean] optional, true=is optional, false=has to be set
    # @return	[Boolean] if zone exists or not set if optional
    def CheckZone(zone, optional)
      # any zone defined
      if zone != "" && zone != nil
        # unknown zone
        if !Builtins.contains(SuSEFirewall.GetKnownFirewallZones, zone)
          # TRANSLATORS: CommandLine error, %1 is a firewall zone shortcut
          CommandLine.Error(Builtins.sformat(_("Unknown zone %1."), zone))
          return false 
          # defined, known zone
        else
          return true
        end 
        # no zone defined
      else
        # not needed, OK
        return true if optional

        # TRANSLATORS: CommandLine error, %1 is needed parameter name
        CommandLine.Error(
          Builtins.sformat(_("Parameter %1 must be set."), "zone")
        )
        return false
      end
    end

    # Function prints table of known firewall zones
    def ListFirewallZones
      CommandLine.Print("")
      # TRANSLATORS: CommandLine header
      CommandLine.Print(
        String.UnderlinedHeader(_("Listing Known Firewall Zones:"), 0)
      )
      CommandLine.Print("")

      table_items = []
      Builtins.foreach(SuSEFirewall.GetKnownFirewallZones) do |zone|
        table_items = Builtins.add(
          table_items,
          [zone, SuSEFirewall.GetZoneFullName(zone)]
        )
      end
      CommandLine.Print(
        String.TextTable(
          [
            # TRANSLATORS: CommandLine table header item
            _("Shortcut"),
            # TRANSLATORS: CommandLine table header item
            _("Zone Name")
          ],
          table_items,
          {}
        )
      )

      CommandLine.Print("")

      nil
    end

    # Calls ListFirewallZones
    #
    # @return [Boolean] always false
    def FWCMDZones(options)
      options = deep_copy(options)
      # listing known zones
      ListFirewallZones() if Ops.get(options, "list") != nil

      # Do not call Write()
      false
    end

    # Prints firewall summary for zones
    #
    # @param [Hash] options
    # @return [Boolean] always false
    def FWCMDSummary(options)
      options = deep_copy(options)
      # printing summary

      # no zone => all zones
      for_zone = Ops.get_string(options, "zone")
      for_zones = []
      if for_zone != nil
        if !CheckZone(for_zone, false)
          return false
        else
          for_zones = [for_zone]
        end
      end

      CommandLine.Print("")
      # TRANSLATORS: CommandLine header
      CommandLine.Print(String.UnderlinedHeader(_("Summary:"), 0))
      CommandLine.Print("")
      if firewalld?
        if for_zones.empty?
          CommandLine.Print(SuSEFirewall.fwd_api.list_all_zones.join("\n"))
        else
          for_zones.each do |zone|
            CommandLine.Print(SuSEFirewall.fwd_api.list_all_zone(zone).join("\n"))
          end
        end
      else
        CommandLine.Print(InitBoxSummary(for_zones))
      end

      # Do not call Write()
      false
    end

    # Sets startup details
    #
    # @return [Boolean] always true
    def FWCMDStartup(options)
      options = deep_copy(options)
      if Ops.get(options, "atboot") != nil && Ops.get(options, "manual") != nil
        # TRANSLATORS: CommandLine error message
        CommandLine.Error(_("Only one parameter is allowed."))
      elsif Ops.get(options, "atboot") != nil
        CommandLine.Print("")
        # TRANSLATORS: CommandLine header
        CommandLine.Print(String.UnderlinedHeader(_("Start-Up:"), 0))
        CommandLine.Print("")
        # TRANSLATORS: CommandLine progress information
        CommandLine.Print(_("Enabling firewall in the boot process..."))
        CommandLine.Print("")
        SuSEFirewall.SetEnableService(true)
      elsif Ops.get(options, "manual") != nil
        CommandLine.Print("")
        # TRANSLATORS: CommandLine header
        CommandLine.Print(String.UnderlinedHeader(_("Start-Up:"), 0))
        CommandLine.Print("")
        # TRANSLATORS: CommandLine progress information
        CommandLine.Print(_("Removing firewall from the boot process..."))
        CommandLine.Print("")
        SuSEFirewall.SetEnableService(false)
      elsif Ops.get(options, "show") != nil
        CommandLine.Print("")
        # TRANSLATORS: CommandLine header
        CommandLine.Print(String.UnderlinedHeader(_("Start-Up:"), 0))
        CommandLine.Print("")
        if SuSEFirewall.GetEnableService
          # TRANSLATORS: CommandLine informative text
          CommandLine.Print(_("Firewall is enabled in the boot process"))
        else
          # TRANSLATORS: CommandLine informative text
          CommandLine.Print(_("Firewall needs manual starting"))
        end
        CommandLine.Print("")
      end

      true
    end

    # Sets network interface assignment
    #
    # @param [Hash] options
    # @return [Boolean] whether write call is needed
    def FWCMDInterfaces(options)
      options = deep_copy(options)
      unassigned_interfaces = []
      interfaces = {}
      Builtins.foreach(SuSEFirewall.GetAllKnownInterfaces) do |interface|
        Ops.set(interfaces, Ops.get(interface, "id", ""), interface)
        if Ops.get(interface, "zone") == nil
          unassigned_interfaces = Builtins.add(
            unassigned_interfaces,
            Ops.get(interface, "id")
          )
        end
      end
      for_zone = Ops.get_string(options, "zone")
      return false if !CheckZone(for_zone, true)

      CommandLine.Print("")
      # creating current configuration list
      if Ops.get(options, "show") != nil
        # TRANSLATORS: CommandLine header
        CommandLine.Print(
          String.UnderlinedHeader(_("Network Interfaces in Firewall Zones:"), 0)
        )
        CommandLine.Print("")

        table_items = []
        Builtins.foreach(SuSEFirewall.GetKnownFirewallZones) do |zone|
          # for_zone defined but it is not current zone
          next if for_zone != nil && for_zone != zone
          Builtins.foreach(SuSEFirewall.GetInterfacesInZone(zone)) do |interface|
            table_items = Builtins.add(
              table_items,
              [zone, interface, Ops.get(interfaces, [interface, "name"], "")]
            )
          end
          Builtins.foreach(SuSEFirewall.GetSpecialInterfacesInZone(zone)) do |spec_int|
            # TRANSLATORS: CommandLine table item (unknown/special string/interface)
            table_items = Builtins.add(
              table_items,
              [zone, spec_int, _("Special firewall string")]
            )
          end
        end
        # print unassigned only in general view
        if for_zone == nil &&
            Ops.greater_than(Builtins.size(unassigned_interfaces), 0)
          Builtins.foreach(unassigned_interfaces) do |interface|
            table_items = Builtins.add(
              table_items,
              ["---", interface, Ops.get(interfaces, [interface, "name"], "")]
            )
          end
        end
        CommandLine.Print(
          String.TextTable(
            [
              # TRANSLATORS: CommandLine table header item
              _("Zone"),
              # TRANSLATORS: CommandLine table header item
              _("Interface"),
              # TRANSLATORS: CommandLine table header item
              _("Device Name")
            ],
            table_items,
            {}
          )
        )
      elsif Ops.get(options, "add") != nil
        interface = Ops.get_string(options, "interface")
        if interface == nil
          # TRANSLATORS: CommandLine error, %1 is needed parameter name
          CommandLine.Error(
            Builtins.sformat(_("Parameter %1 must be set."), "interface")
          )
          return false
        end
        if for_zone == nil
          # TRANSLATORS: CommandLine error, %1 is needed parameter name
          CommandLine.Error(
            Builtins.sformat(_("Parameter %1 must be set."), "zone")
          )
          return false
        end
        # unknown interface
        if Ops.get(interfaces, interface, {}) == {}
          # TRANSLATORS: CommandLine progress information, %1 is the special string, %2 is the zone name
          CommandLine.Print(
            Builtins.sformat(
              _("Adding special string %1 into zone %2..."),
              interface,
              for_zone
            )
          )
          SuSEFirewall.AddSpecialInterfaceIntoZone(interface, for_zone)
        else
          # TRANSLATORS: CommandLine progress information, %1 is the network interface name, %2 is the zone name
          CommandLine.Print(
            Builtins.sformat(
              _("Adding interface %1 into zone %2..."),
              interface,
              for_zone
            )
          )
          SuSEFirewall.AddInterfaceIntoZone(interface, for_zone)
        end
      end
      if Ops.get(options, "remove") != nil
        interface = Ops.get_string(options, "interface")
        if interface == nil
          # TRANSLATORS: CommandLine error, %1 is needed parameter name
          CommandLine.Error(
            Builtins.sformat(_("Parameter %1 must be set."), "interface")
          )
          return false
        end
        if for_zone == nil
          # TRANSLATORS: CommandLine error, %1 is needed parameter name
          CommandLine.Error(
            Builtins.sformat(_("Parameter %1 must be set."), "zone")
          )
          return false
        end
        # unknown interface
        if Ops.get(interfaces, interface, {}) == {}
          # TRANSLATORS: CommandLine progress information, %1 is the special string, %2 is the zone name
          CommandLine.Print(
            Builtins.sformat(
              _("Removing special string %1 from zone %2..."),
              interface,
              for_zone
            )
          )
          SuSEFirewall.RemoveSpecialInterfaceFromZone(interface, for_zone)
        else
          # TRANSLATORS: CommandLine progress information, %1 is the network interface name, %2 is the zone name
          CommandLine.Print(
            Builtins.sformat(
              _("Removing interface %1 from zone %2..."),
              interface,
              for_zone
            )
          )
          SuSEFirewall.RemoveInterfaceFromZone(interface, for_zone)
        end
      end
      CommandLine.Print("")

      true
    end

    # Sets logging details
    #
    # @param [Hash] options
    # @return [Boolean] whether write is needed
    def FWCMDLogging(options)
      options = deep_copy(options)
      logging_meaning = {
        # TRANSLATORS: CommandLine table item
        "ALL"  => _("Log all"),
        # TRANSLATORS: CommandLine table item
        "CRIT" => _("Log only critical"),
        # TRANSLATORS: CommandLine table item
        "NONE" => _("Do not log any")
      }

      if Ops.get(options, "show") != nil
        log_accepted = SuSEFirewall.GetLoggingSettings("ACCEPT")
        log_nonaccepted = SuSEFirewall.GetLoggingSettings("DROP")

        CommandLine.Print("")
        # TRANSLATORS: CommandLine header
        CommandLine.Print(
          String.UnderlinedHeader(_("Global Logging Settings:"), 0)
        )
        CommandLine.Print("")

        CommandLine.Print(
          String.TextTable(
            [
              # TRANSLATORS: CommandLine table header item
              _("Rule Type"),
              # TRANSLATORS: CommandLine table header item
              _("Value"),
              _("Logging Level")
            ],
            [
              # TRANSLATORS: CommandLine table item
              [
                _("Accepted"),
                Builtins.tolower(log_accepted),
                Ops.get(logging_meaning, log_accepted, "Software Error")
              ],
              # TRANSLATORS: CommandLine table item
              [
                _("Not accepted"),
                Builtins.tolower(log_nonaccepted),
                Ops.get(logging_meaning, log_nonaccepted, "Software Error")
              ]
            ],
            {}
          )
        )
        CommandLine.Print("")

        # TRANSLATORS: CommandLine header
        CommandLine.Print(
          String.UnderlinedHeader(_("Logging Broadcast Packets:"), 0)
        )
        CommandLine.Print("")

        table_items = []
        Builtins.foreach(SuSEFirewall.GetKnownFirewallZones) do |zone|
          table_items = Builtins.add(
            table_items,
            [
              zone,
              SuSEFirewall.GetZoneFullName(zone),
              SuSEFirewall.GetIgnoreLoggingBroadcast(zone) == "yes" ?
                # TRANSLATORS: CommandLine table item
                _("Logging enabled") :
                # TRANSLATORS: CommandLine table item
                _("Logging disabled")
            ]
          )
        end
        CommandLine.Print(
          String.TextTable(
            [
              # TRANSLATORS: CommandLine table header item
              _("Short"),
              # TRANSLATORS: CommandLine table header item
              _("Zone Name"),
              # TRANSLATORS: CommandLine table header item
              _("Logging Status")
            ],
            table_items,
            {}
          )
        )
        CommandLine.Print("")

        return false
      elsif Ops.get(options, "set") != nil
        possible_levels = ["all", "crit", "none"]
        if Ops.get(options, "accepted") != nil
          value = Builtins.tolower(Ops.get_string(options, "accepted"))
          if !Builtins.contains(possible_levels, value)
            # TRANSLATORS: CommandLine error message, %1 is an option value, %2 is an option name
            CommandLine.Error(
              Builtins.sformat(
                _("Value %1 is not allowed for option %2."),
                Ops.get(options, "accepted"),
                "accepted"
              )
            )
            return false
          end
          SuSEFirewall.SetLoggingSettings("ACCEPT", Builtins.toupper(value))
        end
        if Ops.get(options, "nonaccepted") != nil
          value = Builtins.tolower(Ops.get_string(options, "nonaccepted"))
          if !Builtins.contains(possible_levels, value)
            # TRANSLATORS: CommandLine error message, %1 is an option value, %2 is an option name
            CommandLine.Error(
              Builtins.sformat(
                _("Value %1 is not allowed for option %2."),
                Ops.get(options, "nonaccepted"),
                "nonaccepted"
              )
            )
            return false
          end
          SuSEFirewall.SetLoggingSettings("DROP", Builtins.toupper(value))
        end
        if Ops.get(options, "logbroadcast") != nil
          zones_to_setup = SuSEFirewall.GetKnownFirewallZones
          # zone defined
          zone = Ops.get_string(options, "zone")
          # zone is defined
          if zone != nil
            # defined, but wrong
            if !CheckZone(zone, false)
              return false 
              # defined well
            else
              zones_to_setup = [zone]
            end
          end

          value = Builtins.tolower(Ops.get_string(options, "logbroadcast"))
          if !Builtins.contains(["yes", "no"], value)
            # TRANSLATORS: CommandLine error message, %1 is an option value, %2 is an option name
            CommandLine.Error(
              Builtins.sformat(
                _("Value %1 is not allowed for option %2."),
                Ops.get(options, "logbroadcast"),
                "logbroadcast"
              )
            )
            return false
          end

          Builtins.foreach(zones_to_setup) do |zone2|
            SuSEFirewall.SetIgnoreLoggingBroadcast(zone2, value)
          end
        end

        return true
      end

      nil
    end

    # Sets broadcast
    #
    # @param [Hash] options
    # @return [Boolean] if write is needed
    def FWCMDBroadcast(options)
      options = deep_copy(options)
      if Ops.get(options, "show") != nil
        # all zones if no zone is defined
        for_zones = SuSEFirewall.GetKnownFirewallZones
        zone = Ops.get_string(options, "zone", "")
        if zone != ""
          if !CheckZone(zone, false)
            return false
          else
            for_zones = [zone]
          end
        end

        CommandLine.Print("")
        # TRANSLATORS: CommandLine header
        CommandLine.Print(
          String.UnderlinedHeader(_("Allowed Broadcast Ports:"), 0)
        )
        CommandLine.Print("")
        table_items = []
        broadcast_ports = SuSEFirewall.GetBroadcastAllowedPorts
        Builtins.foreach(for_zones) do |zone2|
          zone_name = SuSEFirewall.GetZoneFullName(zone2)
          Builtins.foreach(Ops.get(broadcast_ports, zone2, [])) do |port|
            table_items = Builtins.add(table_items, [zone2, zone_name, port])
          end
        end
        CommandLine.Print(
          String.TextTable(
            [
              # TRANSLATORS: CommandLine header item
              _("Short"),
              # TRANSLATORS: CommandLine header item
              _("Zone Name"),
              # TRANSLATORS: CommandLine header item
              _("Port")
            ],
            table_items,
            {}
          )
        )
        CommandLine.Print("")

        return false
      elsif Ops.get(options, "add") != nil && Ops.get(options, "remove") != nil
        # TRANSLATORS: CommandLine error message
        CommandLine.Error(_("Only one action command is allowed here."))
        return false
      elsif Ops.get(options, "add") != nil || Ops.get(options, "remove") != nil
        # undefined zone
        if Ops.get(options, "zone") == nil
          # TRANSLATORS: CommandLine error, %1 is needed parameter name
          CommandLine.Error(
            Builtins.sformat(_("Parameter %1 must be set."), "zone")
          )
          return false
        end
        # unknown zone
        zone = Ops.get_string(options, "zone")
        return false if !CheckZone(zone, false)

        # undefined port
        if Ops.get(options, "port") == nil
          # TRANSLATORS: CommandLine error, %1 is needed parameter name
          CommandLine.Error(
            Builtins.sformat(_("Parameter %1 must be set."), "port")
          )
          return false
        end

        todo = ""
        if Ops.get(options, "add") != nil
          todo = "add"
        elsif Ops.get(options, "remove") != nil
          todo = "remove"
        end

        broadcast_ports = SuSEFirewall.GetBroadcastAllowedPorts
        Builtins.foreach(
          CommaSeparatedList(Ops.get_string(options, "port", ""))
        ) do |port|
          if todo == "add"
            Ops.set(
              broadcast_ports,
              zone,
              Builtins.toset(
                Builtins.add(Ops.get(broadcast_ports, zone, []), port)
              )
            )
          else
            Ops.set(
              broadcast_ports,
              zone,
              Builtins.filter(Ops.get(broadcast_ports, zone, [])) do |filter_port|
                filter_port != port
              end
            )
          end
        end

        SuSEFirewall.SetBroadcastAllowedPorts(broadcast_ports)
        return true
      end

      false
    end

    # Prints all known firewall services
    def FWCMDServicesList
      CommandLine.Print("")
      # TRANSLATORS: CommandLine header
      CommandLine.Print(
        String.UnderlinedHeader(_("Defined Firewall Services:"), 0)
      )
      table_items = []
      Builtins.foreach(SuSEFirewallServices.GetSupportedServices) do |service_id, service_name|
        table_items = Builtins.add(table_items, [service_id, service_name])
      end
      CommandLine.Print("")
      CommandLine.Print(
        String.TextTable(
          [
            # TRANSLATORS: CommandLine table header item
            _("ID"),
            # TRANSLATORS: CommandLine table header item
            _("Service Name")
          ],
          table_items,
          {}
        )
      )
      CommandLine.Print("")

      nil
    end

    # Prints currently allowed services
    #
    # @param [Array<String>] for_zones
    # @param [Boolean] detailed
    def FWCMDServicesShow(for_zones, detailed)
      for_zones = deep_copy(for_zones)
      known_services = SuSEFirewallServices.GetSupportedServices
      protect_from_INT = SuSEFirewall.GetProtectFromInternalZone

      detailed_def = {
        # TRANSLATORS: CommandLine table item
        "tcp_ports"    => _("TCP port"),
        # TRANSLATORS: CommandLine table item
        "udp_ports"    => _("UDP port"),
        # TRANSLATORS: CommandLine table item
        "rpc_ports"    => _("RPC port"),
        # TRANSLATORS: CommandLine table item
        "ip_protocols" => _("IP protocol")
      }

      CommandLine.Print("")
      # TRANSLATORS: CommandLine header
      CommandLine.Print(
        String.UnderlinedHeader(_("Allowed Services in Zones:"), 0)
      )
      CommandLine.Print("")
      table_items = []
      Builtins.foreach(SuSEFirewall.GetKnownFirewallZones) do |zone|
        next if !Builtins.contains(for_zones, zone)
        if zone == "INT" && protect_from_INT == false
          table_items = Builtins.add(
            table_items,
            [
              zone,
              # TRANSLATORS: CommandLine table item (all firewall services are allowed in this zone)
              "*" +
                _("All services") + "*",
              # TRANSLATORS: CommandLine table item (this zone is not protected at all)
              "*" +
                _("Entire zone unprotected") + "*"
            ]
          )
          next
        end
        Builtins.foreach(known_services) do |service_id, service_name|
          if SuSEFirewall.IsServiceSupportedInZone(service_id, zone)
            table_items = Builtins.add(
              table_items,
              [zone, service_id, service_name]
            )
            # detailed listing of used ports
            if detailed
              needed_ports = SuSEFirewallServices.GetNeededPortsAndProtocols(
                service_id
              )
              Builtins.foreach(
                ["tcp_ports", "udp_ports", "rpc_ports", "ip_protocols"]
              ) do |short_def|
                if Ops.greater_than(
                    Builtins.size(Ops.get(needed_ports, short_def, [])),
                    0
                  )
                  Builtins.foreach(Ops.get(needed_ports, short_def, [])) do |port|
                    table_items = Builtins.add(
                      table_items,
                      [
                        "",
                        Builtins.sformat(
                          "> %1: %2",
                          Ops.get(detailed_def, short_def, ""),
                          port
                        )
                      ]
                    )
                    table_items = Builtins.add(table_items, [""])
                  end
                end
              end
            end
          end
        end
      end
      CommandLine.Print(
        String.TextTable(
          [
            # TRANSLATORS: CommandLine table header item
            _("Zone"),
            # TRANSLATORS: CommandLine table header item
            _("Service ID"),
            # TRANSLATORS: CommandLine table header item
            _("Service Name")
          ],
          table_items,
          {}
        )
      )

      CommandLine.Print("")
      # TRANSLATORS: CommandLine header
      CommandLine.Print(
        String.UnderlinedHeader(_("Additional Allowed Ports:"), 0)
      )
      CommandLine.Print("")
      table_items = []
      Builtins.foreach(SuSEFirewall.GetKnownFirewallZones) do |zone|
        next if !Builtins.contains(for_zones, zone)
        if zone == "INT" && protect_from_INT == false
          table_items = Builtins.add(
            table_items,
            [
              zone,
              # TRANSLATORS: CommandLine table item (all ports are allowed in this zone)
              "*" +
                _("All ports") + "*",
              # TRANSLATORS: CommandLine table item (this zone is not protected at all)
              "*" +
                _("Entire zone unprotected") + "*"
            ]
          )
          next
        end
        Builtins.foreach(["TCP", "UDP", "RPC"]) do |protocol|
          Builtins.foreach(SuSEFirewall.GetAdditionalServices(protocol, zone)) do |port|
            table_items = Builtins.add(table_items, [zone, protocol, port])
          end
        end
      end
      CommandLine.Print(
        String.TextTable(
          [
            # TRANSLATORS: CommandLine table header item
            _("Zone"),
            # TRANSLATORS: CommandLine table header item
            _("Protocol"),
            # TRANSLATORS: CommandLine table header item
            _("Port")
          ],
          table_items,
          {}
        )
      )
      CommandLine.Print("")

      CommandLine.Print("")
      # TRANSLATORS: CommandLine header
      CommandLine.Print(
        String.UnderlinedHeader(
          _("Allowed Additional IP Protocols in Zones:"),
          0
        )
      )
      CommandLine.Print("")
      table_items = []
      Builtins.foreach(SuSEFirewall.GetKnownFirewallZones) do |zone|
        next if !Builtins.contains(for_zones, zone)
        if zone == "INT" && protect_from_INT == false
          table_items = Builtins.add(
            table_items,
            [
              zone,
              # TRANSLATORS: CommandLine table item (all protocols are allowed in this zone)
              "*" +
                _("All IP protocols") + "*",
              # TRANSLATORS: CommandLine table item (this zone is not protected at all)
              "*" +
                _("Entire zone unprotected") + "*"
            ]
          )
          next
        end
        Builtins.foreach(SuSEFirewall.GetAdditionalServices("IP", zone)) do |protocol|
          table_items = Builtins.add(table_items, [zone, protocol])
        end
      end
      CommandLine.Print(
        String.TextTable(
          [
            # TRANSLATORS: CommandLine table header item
            _("Zone"),
            # TRANSLATORS: CommandLine table header item
            _("IP Protocol")
          ],
          table_items,
          {}
        )
      )
      CommandLine.Print("")

      nil
    end

    # Adds/removes services to/from zone.
    #
    # @param [String] action ("add" or "remove")
    # @param [String] zone
    # @param [Array<String>] services
    def FWCMDServicesDefinedServicesManagement(action, zone, services)
      services = deep_copy(services)
      Builtins.foreach(services) do |service|
        if !SuSEFirewallServices.IsKnownService(service)
          # TRANSLATORS: CommandLine error message, %1 is a service id
          CommandLine.Error(Builtins.sformat(_("Unknown service %1."), service))
          services = Builtins.filter(services) do |service_item|
            service_item != service
          end
        end
      end

      if action == "add"
        SuSEFirewall.SetServicesForZones(services, [zone], true)
      else
        SuSEFirewall.SetServicesForZones(services, [zone], false)
      end

      nil
    end

    # Adds/removes ports to/from zone.
    #
    # @param [String] action ("add" or "remove")
    # @param [String] zone
    # @param [Array<String>] ports_or_protocols
    # @param [String] type
    def FWCMDServicesAdditionalPortsManagement(action, zone, ports_or_protocols, type)
      ports_or_protocols = deep_copy(ports_or_protocols)
      types = {
        "tcpport"    => "TCP",
        "udpport"    => "UDP",
        "rpcport"    => "RPC",
        "ipprotocol" => "IP"
      }
      protocol = Ops.get(types, type)

      if protocol != nil
        current = SuSEFirewall.GetAdditionalServices(protocol, zone)
        if action == "add"
          current = Convert.convert(
            Builtins.union(current, ports_or_protocols),
            :from => "list",
            :to   => "list <string>"
          )
        else
          current = Builtins.filter(current) do |check_item|
            !Builtins.contains(ports_or_protocols, check_item)
          end
        end
        SuSEFirewall.SetAdditionalServices(protocol, zone, current)
      else
        Builtins.y2error("Software error %1", type)
      end

      nil
    end

    # Sets protect-from value
    #
    # @param [String] zone (only "INT" is supported)
    # @param [String] protect "yes" or "no"
    def FWCMDServicesProtect(zone, protect)
      protect = Builtins.tolower(protect)
      if !Builtins.contains(["yes", "no"], protect)
        # TRANSLATORS: CommandLine error message, %1 is an option value, %2 is an option name
        CommandLine.Error(
          Builtins.sformat(
            _("Value %1 is not allowed for option %2."),
            protect,
            "protect"
          )
        )
        return nil
      end
      # Only Protect from Internal is supported
      if zone != "INT"
        # TRANSLATORS: CommandLine error message
        CommandLine.Error(_("Protection can only be set for internal zones."))
        return nil
      end
      SuSEFirewall.SetProtectFromInternalZone(protect == "yes")

      nil
    end

    # Overall handler function for services
    #
    # @param [Hash] options
    # @return [Boolean] whether write call is needed
    def FWCMDServices(options)
      options = deep_copy(options)
      # listing all known defined services
      if Ops.get(options, "list") != nil
        FWCMDServicesList()
        return false
      elsif Ops.get(options, "show") != nil
        known_zones = SuSEFirewall.GetKnownFirewallZones
        for_zone = Ops.get_string(options, "zone")
        if for_zone != nil
          if !CheckZone(for_zone, true)
            return false
          else
            known_zones = [for_zone]
          end
        end
        FWCMDServicesShow(known_zones, Ops.get(options, "detailed") != nil)
        return false
      elsif Ops.get(options, "add") != nil && Ops.get(options, "remove") != nil
        # TRANSLATORS: CommandLine error message
        CommandLine.Error(_("Only one action command is allowed here."))
      elsif Ops.get(options, "add") != nil || Ops.get(options, "remove") != nil
        zone = Ops.get_string(options, "zone", "")
        return false if !CheckZone(zone, false)

        # add o remove
        action = "add"
        action = "remove" if Ops.get(options, "remove") != nil

        count_entries = 0
        Builtins.foreach(
          ["service", "tcpport", "udpport", "rpcport", "ipprotocol"]
        ) do |type|
          items = CommaSeparatedList(Ops.get_string(options, type, ""))
          if Ops.greater_than(Builtins.size(items), 0)
            count_entries = Ops.add(count_entries, 1)
            if type == "service"
              FWCMDServicesDefinedServicesManagement(action, zone, items)
            else
              FWCMDServicesAdditionalPortsManagement(action, zone, items, type)
            end
          end
        end

        # checking if any action was set along with an action command
        if count_entries == 0
          CommandLine.Error(
            Builtins.sformat(
              # TRANSLATORS: CommandLine error message, %1 is a list of possible entries (without translation)
              _("At least one of %1 must be set."),
              "service, tcpport, udpport, rpcport, protocol"
            )
          )
        end
        return true
      elsif Ops.get(options, "protect") != nil
        zone = Ops.get_string(options, "zone", "")
        return false if !CheckZone(zone, false)

        FWCMDServicesProtect(zone, Ops.get_string(options, "protect"))
      else
        CommandLine.Error(
          Builtins.sformat(
            # TRANSLATORS: CommandLine error message, %1 is a list of possible action commands
            _("At least one action command from %1 must be set."),
            "list, show, add, remove"
          )
        )
      end

      nil
    end

    # Prints the table of the current redirect-to-masquerade rules
    #
    # @param [Hash] options
    def FWCMDMasqRedirectShow(options)
      options = deep_copy(options)
      CommandLine.Print("")
      # TRANSLATORS: CommandLine header
      CommandLine.Print(
        String.UnderlinedHeader(_("Redirect Requests to Masqueraded IP:"), 0)
      )
      CommandLine.Print("")

      table_items = []
      records = SuSEFirewall.GetListOfForwardsIntoMasquerade
      counter = 0
      Builtins.foreach(records) do |record|
        counter = Ops.add(counter, 1)
        # if redirect_to_port is not defined, use the same as requested_port
        if Ops.get(record, "to_port", "") == "" ||
            Ops.get(record, "to_port", "") == nil
          Ops.set(record, "to_port", Ops.get(record, "req_port", ""))
        end
        # using port names instead of port numbers
        if Ops.get(options, "names") != nil
          Builtins.foreach(["to_port", "req_port"]) do |key|
            port_name = GetPortName(Ops.get(record, key, ""))
            Ops.set(record, key, port_name) if port_name != nil
          end
        end
        table_items = Builtins.add(
          table_items,
          [
            Builtins.tostring(counter),
            Ops.get(record, "source_net", ""),
            Ops.get(record, "protocol", ""),
            Ops.get(record, "req_ip", ""),
            Ops.get(record, "req_port", ""),
            Ops.get(record, "forward_to", ""),
            Ops.get(record, "to_port", "")
          ]
        )
      end
      CommandLine.Print(
        String.TextTable(
          [
            # TRANSLATORS: CommandLine table header item
            _("ID"),
            # TRANSLATORS: CommandLine table header item
            _("Source Network"),
            # TRANSLATORS: CommandLine table header item
            _("Protocol"),
            # TRANSLATORS: CommandLine table header item, Req.=Requested
            _("Req. IP"),
            # TRANSLATORS: CommandLine table header item, Req.=Requested
            _("Req. Port"),
            # TRANSLATORS: CommandLine table header item, Redir.=Redirect
            _("Redir. to IP"),
            # TRANSLATORS: CommandLine table header item, Redir.=Redirect
            _("Redir. to Port")
          ],
          table_items,
          {}
        )
      )
      CommandLine.Print("")

      nil
    end

    # Overall handler for redirect to masqueraded network
    #
    # @param [Hash] options
    # @return [Boolean] whether write call is needed
    def FWCMDMasqRedirect(options)
      options = deep_copy(options)
      if Ops.get(options, "show") != nil
        FWCMDMasqRedirectShow(options)
        return false
      elsif Ops.get(options, "add") != nil
        # checking existency
        checked = true
        Builtins.foreach(["sourcenet", "protocol", "req_port", "redir_ip"]) do |option|
          if Ops.get(options, option) == nil
            # TRANSLATORS: CommandLine error, %1 is needed parameter name
            CommandLine.Error(
              Builtins.sformat(_("Parameter %1 must be set."), option)
            )
            checked = false
          end
        end
        return false if !checked

        # filling strings
        new = {}
        Builtins.foreach(
          [
            "sourcenet",
            "protocol",
            "req_port",
            "redir_ip",
            "req_ip",
            "redir_port"
          ]
        ) { |option| Ops.set(new, option, Ops.get_string(options, option, "")) }

        # checking format
        Ops.set(new, "protocol", Builtins.tolower(Ops.get(new, "protocol", "")))
        if !Builtins.contains(["tcp", "udp"], Ops.get(new, "protocol", ""))
          # TRANSLATORS: CommandLine error message, %1 is an option value, %2 is an option name
          CommandLine.Error(
            Builtins.sformat(
              _("Value %1 is not allowed for option %2."),
              Ops.get(new, "protocol", ""),
              "protocol"
            )
          )
          return false
        end

        # checking port names (if known)
        port_errors = ""
        Builtins.foreach(["req_port", "redir_port"]) do |key|
          if Ops.get(new, key) != nil
            port_number = Builtins.tostring(
              GetPortNumber(Ops.get(new, key, ""))
            )
            if port_number != nil
              # internally using port numbers instead port names
              Ops.set(new, key, port_number)
            else
              port_errors = Ops.add(
                Ops.add(port_errors, port_errors != "" ? "\n" : ""),
                # TRANSLATORS: CommandLine error message, %1 is a port name
                Builtins.sformat(
                  _("Unknown port name %1."),
                  Ops.get(new, key, "")
                )
              )
            end
          end
        end
        # there were some errors in port names
        if port_errors != ""
          CommandLine.Error(port_errors)
          return false
        end

        SuSEFirewall.AddForwardIntoMasqueradeRule(
          Ops.get(new, "sourcenet", ""),
          Ops.get(new, "redir_ip", ""),
          Ops.get(new, "protocol", ""),
          Ops.get(new, "req_port", ""),
          Ops.get(new, "redir_port", ""),
          Ops.get(new, "req_ip", "")
        )
        return true
      elsif Ops.get(options, "remove") != nil
        if Ops.get(options, "record") == nil
          # TRANSLATORS: CommandLine error, %1 is needed parameter name
          CommandLine.Error(
            Builtins.sformat(_("Parameter %1 must be set."), "record")
          )
          return false
        end
        record = Ops.get_integer(options, "record", 0)
        # records are printed 1-n but internally are 0-(n-1)
        record = Ops.subtract(record, 1)
        SuSEFirewall.RemoveForwardIntoMasqueradeRule(record)
        return true
      end

      nil
    end

    # Overall masquerade-related handler
    #
    # @param [Hash] options
    # @return [Boolean] whether write call is needed
    def FWCMDMasquerade(options)
      options = deep_copy(options)
      zone = nil
      if firewalld?
        if options["zone"]
          zone = options["zone"].downcase
          if !SuSEFirewall.IsKnownZone(zone)
            # TRANSLATORS: CommandLine error, %1 is zone
            CommandLine.Error(Builtins.sformat(_("Unknown zone %1."), zone))
            return false
          end
        else
          # TRANSLATORS: CommandLine error
          CommandLine.Error("Mandatory 'zone' parameter is missing")
          return false
        end
      end

      if Ops.get(options, "show") != nil
        CommandLine.Print("")
        # TRANSLATORS: CommandLine header
        CommandLine.Print(
          String.UnderlinedHeader(_("Masquerading Settings:"), 0)
        )
        CommandLine.Print("")

       # TRANSLATORS: CommandLine informative text, either "everywhere" or
       # "in the %1 zone" where %1 is zone name.
       zone_msg = zone == nil ? _("everywhere") :
         Builtins.sformat(_("in the %1 zone"), zone)

        CommandLine.Print(
          Builtins.sformat(
            # TRANSLATORS: CommandLine informative text, %1 is "enabled" or "disabled"
            # %2 is previously mentioned zone_msg
            _("Masquerading is %1 %2"),
            SuSEFirewall.GetMasquerade(zone) == true ?
              # TRANSLATORS: CommandLine masquerade status
              _("enabled") :
              # TRANSLATORS: CommandLine masquerade status
              _("disabled"), zone_msg
          )
        )
        CommandLine.Print("")
        return false
      elsif Ops.get(options, "enable") != nil
        SuSEFirewall.SetMasquerade(true, zone)
      elsif Ops.get(options, "disable") != nil
        SuSEFirewall.SetMasquerade(false, zone)
      end

      nil
    end

    # Overall firewall manual enabling handler
    #
    # @param [Hash] options   ignored (no special options)
    # @return [Boolean]      whether write call is needed
    def FWCMDEnable(options)
      options = deep_copy(options)
      SuSEFirewall.SetStartService(true)
      SuSEFirewall.StartServices
    end

    # Overall firewall manual disabling handler
    #
    # @param [Hash] options   ignored (no special options)
    # @return [Boolean]      whether write call is needed
    def FWCMDDisable(options)
      options = deep_copy(options)
      SuSEFirewall.SetStartService(false)
      SuSEFirewall.StartServices
    end

    # Runs the commandline interface for firewall
    def Run
      # variable from SuSEFirewallUI
      SuSEFirewallUI.simple_text_output = true

      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone(
        Builtins.sformat("Starting CommandLine with parameters %1", WFM.Args)
      )
      SummaryInitCommandLine()
      CommandLine.Run(@cmdline)
      Builtins.y2milestone("----------------------------------------")

      nil
    end

  private
    # Returns true if FirewallD is the running backend
    def firewalld?
      SuSEFirewall.is_a?(Yast::SuSEFirewalldClass)
    end

    def ConfigureFirewalld
      return unless firewalld?

      # Actions not supported by FirewallD
      firewalld_disabled = ["broadcast", "masqredirect"]

      firewalld_disabled.each do |opt|
        @cmdline["actions"].delete(opt)
        @cmdline["mappings"].delete(opt)
      end

      @cmdline["actions"]["masquerade"]["example"] << "masquerade zone=public enable"
      @cmdline["mappings"]["masquerade"] <<  "zone"

      # protection from internal zone does not apply to FirewallD
      @cmdline["actions"]["services"]["example"] = [
        "services show detailed",
        "services add service=service:dhcp-server zone=EXT",
        "services remove ipprotocol=esp tcpport=12,13,ipp zone=DMZ"
      ]
      # Remove unsupported options for FirewallD
      @cmdline["mappings"]["services"].delete("rpcport")
      @cmdline["mappings"]["services"].delete("protect")

    end

    publish :function => :Run, :type => "void ()"
  end

  SuSEFirewallCMDLine = SuSEFirewallCMDLineClass.new
  SuSEFirewallCMDLine.main
end
