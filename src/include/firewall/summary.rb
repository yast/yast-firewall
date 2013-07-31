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
# File:	firewall/summary.ycp
# Package:	Firewall configuration
# Summary:	Firewall configuration summary
# Authors:	Lukas Ocilka <locilka@suse.cz>
#
# $Id$
#
# Summary functions.
module Yast
  module FirewallSummaryInclude
    def initialize_firewall_summary(include_target)
      Yast.import "UI"
      textdomain "firewall"

      Yast.import "SuSEFirewall"
      Yast.import "SuSEFirewallServices"
      Yast.import "SuSEFirewallUI"
      Yast.import "SuSEFirewallExpertRules"
      Yast.import "Mode"
      Yast.import "String"

      Yast.include include_target, "firewall/subdialogs.rb"
      Yast.include include_target, "firewall/uifunctions.rb"

      @show_details = false

      @protocol_type_names = {
        # TRANSLATORS: Summary item label
        "TCP" => _("TCP Ports"),
        # TRANSLATORS: Summary item label
        "UDP" => _("UDP Ports"),
        # TRANSLATORS: Summary item label
        "RPC" => _("RPC Services"),
        # TRANSLATORS: Summary item label
        "IP"  => _("IP Protocols"),
        # TRANSLATORS: Summary item label
        "BRD" => _("Broadcast Ports")
      }

      @li_start = "<li>"
      @li_end = "</li>"

      @ul_start = "<ul>"
      @ul_end = "</ul>"
    end

    # Function initializes spacial behaviour for commandline
    def SummaryInitCommandLine
      @li_start = "        * "
      @li_end = ""
      @ul_start = ""
      @ul_end = ""

      nil
    end

    def SummaryZoneHeader(zone_id)
      if SuSEFirewallUI.simple_text_output
        return String.UnderlinedHeader(SuSEFirewall.GetZoneFullName(zone_id), 0)
      else
        return Ops.add(
          Ops.add(
            "\n<h2>",
            String.EscapeTags(SuSEFirewall.GetZoneFullName(zone_id))
          ),
          "</h2>\n"
        )
      end
    end

    def SummaryCheckSpecInterface(spec_interface, zone)
      ret_val = ""

      if spec_interface == "any"
        if zone == "EXT"
          ret_val = Ops.add(
            Ops.add(Ops.add(" '", spec_interface), "' "),
            #(NetworkService::IsManaged() ?
            #    // TRANSLATORS: an informative text, text presented in HTML - newlines are not needed
            #    _("All network interfaces handled by NetworkManager and all other unassigned interfaces will be assigned to this zone.")
            #    :
            # TRANSLATORS: an informative text, text presented in HTML - newlines are not needed
            _("Any unassigned interface will be assigned to this zone.")
          ) 
          #);
        else
          ret_val = Ops.add(
            Ops.add(Ops.add(" '", spec_interface), "' "),
            # TRANSLATORS: informative text
            _("Currently supported only in external zone.")
          )
        end
      else
        # TRANSLATORS: informative text
        ret_val = Ops.add(
          Ops.add(Ops.add(" '", spec_interface), "' "),
          _("Unknown network interface.")
        )
      end

      ret_val
    end

    def SummaryInterfacesInZone(zone_id)
      ret_summary = ""

      interfaces = SuSEFirewall.GetAllKnownInterfaces
      interface_id_to_name = {}
      Builtins.foreach(interfaces) do |interface|
        Ops.set(
          interface_id_to_name,
          Ops.get(interface, "id", ""),
          Ops.get(interface, "name", "")
        )
      end

      interfaces_in_zone = SuSEFirewall.GetInterfacesInZone(zone_id)
      special_interfaces = SuSEFirewall.GetSpecialInterfacesInZone(zone_id)

      if Ops.greater_than(Builtins.size(interfaces_in_zone), 0) ||
          Ops.greater_than(Builtins.size(special_interfaces), 0)
        ret_summary = Ops.add(
          Ops.add(
            ret_summary,
            SuSEFirewallUI.simple_text_output ?
              # TRANSLATORS: Summary item label
              String.UnderlinedHeader(_("Interfaces"), 4) :
              # TRANSLATORS: Summary item label
              "<h3>" + _("Interfaces") + "</h3>"
          ),
          "\n"
        )

        ret_summary = Ops.add(ret_summary, @ul_start)
        Builtins.foreach(interfaces_in_zone) do |interface_id|
          ret_summary = Ops.add(
            Ops.add(
              Ops.add(
                Ops.add(
                  Ops.add(Ops.add(ret_summary, @li_start), " "),
                  Ops.get(interface_id_to_name, interface_id, "") != "" ?
                    Ops.add(
                      String.EscapeTags(
                        Ops.get(interface_id_to_name, interface_id, "")
                      ),
                      " / "
                    ) :
                    ""
                ),
                String.EscapeTags(interface_id)
              ),
              @li_end
            ),
            "\n"
          )
        end
        Builtins.foreach(special_interfaces) do |spec_interface|
          ret_summary = Ops.add(
            Ops.add(
              Ops.add(
                Ops.add(ret_summary, @li_start),
                SummaryCheckSpecInterface(spec_interface, zone_id)
              ),
              @li_end
            ),
            "\n"
          )
        end
        ret_summary = Ops.add(ret_summary, @ul_end)
      else
        # TRANSLATORS: informative text
        ret_summary = Ops.add(
          Ops.add(
            Ops.add(@li_start, _("No interfaces assigned to this zone.")),
            @li_end
          ),
          "\n"
        )
      end

      ret_summary
    end

    # Returns HTML-formatted information about ports contained in a service
    # defined by parameter service_id.
    #
    # @param [String] service_id
    # @return [String] detailed information
    def ShowServiceDetails(service_id)
      tcp_ports = SuSEFirewallServices.GetNeededTCPPorts(service_id)
      udp_ports = SuSEFirewallServices.GetNeededUDPPorts(service_id)
      rpc_ports = SuSEFirewallServices.GetNeededRPCPorts(service_id)
      ip_protocols = SuSEFirewallServices.GetNeededIPProtocols(service_id)
      broadcast_ports = SuSEFirewallServices.GetNeededBroadcastPorts(service_id)

      ret = ""

      # TCP ports
      if Ops.greater_than(Builtins.size(tcp_ports), 0)
        # "ssh" -> "ssh (22)"
        tcp_ports = Builtins.maplist(tcp_ports) do |tcp_port|
          UserReadablePortName(tcp_port, "TCP")
        end
        ret = Ops.add(
          Ops.add(
            Ops.add(
              Ops.add(
                Ops.add(
                  Ops.add(ret, @li_start),
                  Ops.get_string(@protocol_type_names, "TCP", "")
                ),
                ": "
              ),
              Builtins.mergestring(tcp_ports, ", ")
            ),
            @li_end
          ),
          "\n"
        )
      end

      # UDP Ports
      if Ops.greater_than(Builtins.size(udp_ports), 0)
        udp_ports = Builtins.maplist(udp_ports) do |udp_port|
          UserReadablePortName(udp_port, "UDP")
        end
        ret = Ops.add(
          Ops.add(
            Ops.add(
              Ops.add(
                Ops.add(
                  Ops.add(ret, @li_start),
                  Ops.get_string(@protocol_type_names, "UDP", "")
                ),
                ": "
              ),
              Builtins.mergestring(udp_ports, ", ")
            ),
            @li_end
          ),
          "\n"
        )
      end

      # RPC Services
      if Ops.greater_than(Builtins.size(rpc_ports), 0)
        ret = Ops.add(
          Ops.add(
            Ops.add(
              Ops.add(
                Ops.add(
                  Ops.add(ret, @li_start),
                  Ops.get_string(@protocol_type_names, "RPC", "")
                ),
                ": "
              ),
              Builtins.mergestring(rpc_ports, ", ")
            ),
            @li_end
          ),
          "\n"
        )
      end

      # IP Protocols
      if Ops.greater_than(Builtins.size(ip_protocols), 0)
        ret = Ops.add(
          Ops.add(
            Ops.add(
              Ops.add(
                Ops.add(
                  Ops.add(ret, @li_start),
                  Ops.get_string(@protocol_type_names, "IP", "")
                ),
                ": "
              ),
              Builtins.mergestring(ip_protocols, ", ")
            ),
            @li_end
          ),
          "\n"
        )
      end

      # Broadcast (UDP)
      if Ops.greater_than(Builtins.size(broadcast_ports), 0)
        broadcast_ports = Builtins.maplist(broadcast_ports) do |broadcast_port|
          String.EscapeTags(UserReadablePortName(broadcast_port, "UDP"))
        end
        ret = Ops.add(
          Ops.add(
            Ops.add(
              Ops.add(
                Ops.add(
                  Ops.add(ret, @li_start),
                  Ops.get_string(@protocol_type_names, "BRD", "")
                ),
                ": "
              ),
              String.EscapeTags(Builtins.mergestring(broadcast_ports, ", "))
            ),
            @li_end
          ),
          "\n"
        )
      end

      return "" if ret == ""

      Ops.add(Ops.add(Ops.add(Ops.add("\n", @ul_start), ret), @ul_end), "\n")
    end

    def SummaryOpenServicesInZone(zone_id, show_details)
      ret_val = ""

      interfaces_in_zone = SuSEFirewall.GetInterfacesInZone(zone_id)
      special_interfaces = SuSEFirewall.GetSpecialInterfacesInZone(zone_id)

      # any interface must be assigned
      if Ops.greater_than(Builtins.size(interfaces_in_zone), 0) ||
          Ops.greater_than(Builtins.size(special_interfaces), 0)
        ret_val = Ops.add(
          SuSEFirewallUI.simple_text_output ?
            # TRANSLATORS: CommandLine summary header
            String.UnderlinedHeader(_("Open Services, Ports, and Protocols"), 4) :
            # TRANSLATORS: UI summary header
            "<h3>" + _("Open Services, Ports, and Protocols") + "</h3>",
          "\n"
        )
        # internal zone and unprotected
        if zone_id == "INT" && !SuSEFirewall.GetProtectFromInternalZone
          # TRANSLATORS: informative text
          ret_val = Ops.add(
            Ops.add(
              Ops.add(
                Ops.add(
                  Ops.add(Ops.add(ret_val, @ul_start), @li_start),
                  _("Internal zone is unprotected.  All ports are open.")
                ),
                @li_end
              ),
              @ul_end
            ),
            "\n"
          )
        else
          open_services = ""

          translations_to_service_ids = {}
          Builtins.foreach(SuSEFirewallServices.GetSupportedServices) do |service_id, service_name|
            Ops.set(translations_to_service_ids, service_name, service_id)
          end
          # Allowed known services
          Builtins.foreach(translations_to_service_ids) do |service_name, service_id|
            if SuSEFirewall.IsServiceSupportedInZone(service_id, zone_id)
              open_services = Ops.add(
                Ops.add(
                  Ops.add(
                    Ops.add(
                      Ops.add(
                        Ops.add(open_services, @li_start),
                        String.EscapeTags(service_name)
                      ),
                      show_details ? ":" : ""
                    ),
                    @li_end
                  ),
                  show_details ? ShowServiceDetails(service_id) : ""
                ),
                "\n"
              )
            end
          end
          # Additional (unknown) ports, services, protocols...
          Builtins.foreach(["TCP", "UDP", "RPC", "IP"]) do |protocol|
            additional_services = Builtins.mergestring(
              SuSEFirewall.GetAdditionalServices(protocol, zone_id),
              ", "
            )
            next if additional_services == ""
            open_services = Ops.add(
              Ops.add(
                Ops.add(
                  Ops.add(
                    Ops.add(
                      Ops.add(open_services, @li_start),
                      Ops.get_string(@protocol_type_names, protocol, "")
                    ),
                    ": "
                  ),
                  String.EscapeTags(additional_services)
                ),
                @li_end
              ),
              "\n"
            )
          end

          ret_val = Ops.add(
            Ops.add(
              Ops.add(
                Ops.add(ret_val, @ul_start),
                open_services != "" ?
                  open_services :
                  # TRANSLATORS: informative text
                  Ops.add(
                    Ops.add(@li_start, _("Zone has no open ports.")),
                    @li_end
                  )
              ),
              @ul_end
            ),
            "\n"
          )
        end
      end

      ret_val
    end

    def SummaryCustomRules(zone, show_details)
      # FATE #303304: YaST Firewall module shall show custom rules on Summary page
      custom_rules = SuSEFirewallExpertRules.GetListOfAcceptRules(zone)

      if custom_rules == nil
        Builtins.y2error("Wrong custom rules for %1", zone)
        return ""
      elsif Builtins.size(custom_rules) == 0
        Builtins.y2milestone("No custom rules defined")
        return ""
      end

      # Example:
      #   All requests from network 80.44.11.0/24 to UDP port 53 originating on port 53
      #   $[ "network" : "80.44.11.0/24", "protocol" : "udp", "dport" : "53",  "sport" : "53" ]
      #
      # Possible keys for parameters are "network", "protocol", "dport" and "sport".
      # Mandatory are "network" and "protocol".

      rules = "<h3>" + _("Custom Rules") + "</h3>"

      rules = Ops.add(rules, @ul_start)

      if !show_details
        rules = Ops.add(
          Ops.add(
            Ops.add(rules, @li_start),
            Builtins.sformat(
              _("%1 custom rules are defined"),
              Builtins.size(custom_rules)
            )
          ),
          @li_end
        )
      else
        Builtins.foreach(custom_rules) do |one_rule|
          proto = Ops.get(one_rule, "protocol", "tcp")
          one_rule_s = Ops.add(
            Ops.add(
              @li_start,
              Builtins.sformat(
                _(
                  "Network: <i>%1</i>, Protocol: <i>%2</i>, Destination port: <i>%3</i>, Source port: <i>%4</i>, Options: <i>%5</i>"
                ),
                String.EscapeTags(Ops.get(one_rule, "network", _("All"))),
                String.EscapeTags(
                  SuSEFirewall.GetProtocolTranslatedName(
                    Ops.get(one_rule, "protocol", _("All"))
                  )
                ),
                Ops.get(one_rule, "dport", "") != "" ?
                  String.EscapeTags(
                    UserReadablePortName(Ops.get(one_rule, "dport", ""), proto)
                  ) :
                  _("All"),
                Ops.get(one_rule, "sport", "") != "" ?
                  String.EscapeTags(
                    UserReadablePortName(Ops.get(one_rule, "sport", ""), proto)
                  ) :
                  _("All"),
                Ops.get(one_rule, "options", "") != "" ?
                  String.EscapeTags(Ops.get(one_rule, "options", "")) :
                  _("None")
              )
            ),
            @li_end
          )
          rules = Ops.add(rules, one_rule_s)
        end
      end

      rules = Ops.add(rules, @ul_end)

      rules
    end

    def SummaryZoneBody(zone_id, show_details)
      Ops.add(
        Ops.add(
          Ops.add(
            Ops.add(
              Ops.add(
                Ops.add(@ul_start, "\n"),
                SummaryInterfacesInZone(zone_id)
              ),
              SummaryOpenServicesInZone(zone_id, show_details)
            ),
            SummaryCustomRules(zone_id, show_details)
          ),
          @ul_end
        ),
        "\n"
      )
    end

    def SummaryFirewallStart
      # TRANSLATORS: Summary header item
      ret_message = Ops.add(
        Ops.add(
          "\n",
          SuSEFirewallUI.simple_text_output ?
            # TRANSLATORS: CommandLine Summary header
            String.UnderlinedHeader(_("Firewall Starting"), 0) :
            # TRANSLATORS: UI Summary header
            "<h2>" + _("Firewall Starting") + "</h2>"
        ),
        "\n"
      )

      ret_message = Ops.add(ret_message, @ul_start)

      # Firewall is enabled/disabled in the boot process
      if SuSEFirewall.GetEnableService
        # TRANSLATORS: Summary text item
        ret_message = Ops.add(
          Ops.add(
            Ops.add(
              Ops.add(ret_message, @li_start),
              _("<b>Enable</b> firewall automatic starting")
            ),
            @li_end
          ),
          "\n\n"
        )
      else
        # TRANSLATORS: Summary text item
        ret_message = Ops.add(
          Ops.add(
            Ops.add(
              Ops.add(ret_message, @li_start),
              _("<b>Disable</b> firewall automatic starting")
            ),
            @li_end
          ),
          "\n\n"
        )
      end

      # Firewall should be running/stopped
      if SuSEFirewall.GetStartService
        # Is running and will be running again
        if SuSEFirewall.IsStarted
          # TRANSLATORS: Summary text item
          ret_message = Ops.add(
            Ops.add(
              Ops.add(
                Ops.add(ret_message, @li_start),
                _("Firewall starts after the configuration has been written")
              ),
              @li_end
            ),
            "\n"
          ) 
          # Is stopped and will be running
        else
          # TRANSLATORS: Summary text item
          ret_message = Ops.add(
            Ops.add(
              Ops.add(
                Ops.add(ret_message, @li_start),
                _(
                  "Firewall <b>starts</b> after the configuration has been written"
                )
              ),
              @li_end
            ),
            "\n"
          )
        end
      else
        # Is running and will be stopped
        if SuSEFirewall.IsStarted
          # TRANSLATORS: Summary text item
          ret_message = Ops.add(
            Ops.add(
              Ops.add(
                Ops.add(ret_message, @li_start),
                _(
                  "Firewall <b>will be stopped</b> after the configuration has been written"
                )
              ),
              @li_end
            ),
            "\n"
          ) 
          # Is not running and will not be running
        else
          # TRANSLATORS: Summary text item
          ret_message = Ops.add(
            Ops.add(
              Ops.add(
                Ops.add(ret_message, @li_start),
                _(
                  "Firewall will not start after the configuration has been written"
                )
              ),
              @li_end
            ),
            "\n"
          )
        end
      end

      ret_message = Ops.add(Ops.add(ret_message, @ul_end), "\n\n")

      ret_message
    end

    def SummaryUnassignedInterfaces
      ret_message = Ops.add(
        Ops.add(
          "\n",
          SuSEFirewallUI.simple_text_output ?
            # TRANSLATORS: Summary text item
            String.UnderlinedHeader(_("Unassigned Interfaces"), 0) :
            # TRANSLATORS: Summary text item
            "<h2>" + _("Unassigned Interfaces") + "</h2>"
        ),
        "\n"
      )

      special_strings = []
      Builtins.foreach(SuSEFirewall.GetKnownFirewallZones) do |zone|
        special_strings = Convert.convert(
          Builtins.union(
            special_strings,
            SuSEFirewall.GetSpecialInterfacesInZone(zone)
          ),
          :from => "list",
          :to   => "list <string>"
        )
      end

      if Builtins.contains(special_strings, "any") ||
          Builtins.contains(special_strings, "auto")
        Builtins.y2milestone(
          "Special strings 'any' or 'auto' presented, skipping..."
        )
        return ""
      end

      interfaces_unassigned = 0
      ret_message = Ops.add(
        Ops.add(ret_message, @ul_start),
        # TRANSLATORS: Warning plain text in summary
        _("No network traffic is permitted through these interfaces.")
      )
      Builtins.foreach(SuSEFirewall.GetAllKnownInterfaces) do |interface|
        if Ops.get(interface, "zone") == nil
          ret_message = Ops.add(
            Ops.add(
              Ops.add(
                Ops.add(Ops.add(ret_message, @li_start), " "),
                Ops.get(interface, "name") == nil ||
                  Ops.get(interface, "name") == "" ?
                  Ops.get(interface, "id", "") :
                  Builtins.sformat(
                    "%1 / %2",
                    Ops.get(interface, "name", ""),
                    Ops.get(interface, "id", "")
                  )
              ),
              @li_end
            ),
            "\n"
          )
          interfaces_unassigned = Ops.add(interfaces_unassigned, 1)
        end
      end
      ret_message = Ops.add(Ops.add(ret_message, @ul_end), "\n")

      # no need to return the headline when all interfaces are assigned
      return "" if interfaces_unassigned == 0

      ret_message
    end



    def InitBoxSummary(for_zones)
      for_zones = deep_copy(for_zones)
      @show_details = SuSEFirewallUI.GetShowSummaryDetails
      Builtins.y2milestone(
        "Regenerating summary dialog, details: %1",
        @show_details
      )

      # just as first init
      UI.ChangeWidget(Id("show_details"), :Value, @show_details)

      summary = Ops.add(
        Ops.add(SummaryFirewallStart(), "<hr />"),
        SummaryUnassignedInterfaces()
      )

      if Builtins.size(for_zones) == 0
        for_zones = SuSEFirewall.GetKnownFirewallZones
      end

      Builtins.foreach(SuSEFirewall.GetKnownFirewallZones) do |zone_id|
        if Builtins.contains(for_zones, zone_id)
          summary = Ops.add(
            Ops.add(summary, SummaryZoneHeader(zone_id)),
            SummaryZoneBody(zone_id, @show_details)
          )
        end
      end

      if Mode.normal && !Mode.commandline
        UI.ChangeWidget(Id("box_summary_richtext"), :Value, summary)
      end

      summary
    end
  end
end
