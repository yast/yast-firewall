# encoding: utf-8

# ***************************************************************************
#
# Copyright (c) 2000 - 2013 Novell, Inc.
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
# File:        firewall/uifunctions.ycp
# Package:     Configuration YaST2 Firewall
# Summary:     Configuration dialogs handling functions
# Authors:     Lukas Ocilka <locilka@suse.cz>
#
# $Id$
#
# Configuration dialogs handling.
# Both Expert and Simple.
module Yast
  module FirewallUifunctionsInclude
    def initialize_firewall_uifunctions(include_target)
      Yast.import "UI"
      textdomain "firewall"

      Yast.import "Confirm"
      Yast.import "SuSEFirewall"
      Yast.import "SuSEFirewallServices"
      Yast.import "SuSEFirewallExpertRules"
      Yast.import "PortAliases"
      Yast.import "Popup"
      Yast.import "Wizard"
      Yast.import "Report"
      Yast.import "Label"
      Yast.import "Mode"
      Yast.import "IP"
      Yast.import "Netmask"
      Yast.import "PortRanges"

      Yast.include include_target, "firewall/generalfunctions.rb"
      Yast.include include_target, "firewall/helps.rb"
      Yast.include include_target, "firewall/subdialogs.rb"

      # GLOBAL UI CONFIGURATION
      @all_popup_definition = Opt(:decorated, :centered)

      # maximum length of the string "Interface Name" (min. 3)
      @max_length_intname = 35

      # map of device names
      @known_device_names = {}

      @firewall_enabled_st = nil
      @firewall_started_st = nil

      @customrules_current_zone = nil

      @service_to_protocol = {
        "samba"   => "udp",
        "slp"     => "udp",
        "all-udp" => "udp",
        "all-ycp" => "udp"
      }

      @service_to_port = {
        "samba"   => "137",
        "slp"     => "427",
        "all-udp" => "",
        "all-tcp" => ""
      }
    end

    # EXAMPLE FUNCTIONS
    #    void ExampleInit(string key) {
    #	y2milestone("Example Init");
    #    }
    #
    #    symbol ExampleHandle(string key, map event) {
    #	any ret = event["ID"]:nil;
    #	y2milestone("Example Handle");
    #	return nil;
    #    }
    #
    #    void ExampleStore(string key, map event) {
    #	any ret = event["ID"]:nil;
    #	y2milestone("Example Store");
    #    }
    #

    # UI Functions

    # Sets the dialog icon.
    def SetFirewallIcon
      Wizard.SetTitleIcon("yast-firewall")

      nil
    end

    # Function disables the back button.
    # Fake function for CWM Tree Widget.
    def DisableBackButton(key)
      SetFirewallIcon()
      UI.ChangeWidget(Id(:back), :Enabled, false)

      nil
    end

    # Function saves configuration and restarts firewall
    def SaveAndRestart
      Wizard.CreateDialog
      Wizard.RestoreHelp(HelpForDialog("saving_configuration"))
      success = SuSEFirewall.SaveAndRestartService
      success ? SuSEFirewall.SetStartService(true) : report_problem(:start)
      Builtins.sleep(500)
      UI.CloseDialog

      success
    end

    # Function starts Firewall services and sets firewall
    # to be started after exiting YaST
    def StartNow
      UI.OpenDialog(Label(_("Starting firewall...")))
      SuSEFirewall.SetStartService(true)
      success = SuSEFirewall.StartServices
      report_problem(:start) unless success
      UI.CloseDialog

      success
    end

    # Function stops Firewall services and sets firewall
    # to be stopped after exiting YaST
    def StopNow
      UI.OpenDialog(Label(_("Stopping firewall...")))
      SuSEFirewall.SetStartService(false)
      success = SuSEFirewall.StopServices
      report_problem(:stop) unless success
      UI.CloseDialog

      success
    end

    def report_problem(action)
      action_str = case action
      when :stop
        # TRANSLATORS: action which failed, used later
        _("The firewall could not be stopped.")
      when :start
        # TRANSLATORS: action which failed, used later
        _("The firewall could not be started.")
      else
        raise "invalid action #{action}"
      end
      # TRANSLATORS: %s is action that failed
      msg = _(
        "%s\n" +
        "Please verify your system and try again."
      ) % action_str
      Popup.Error(msg)
    end

    # Function sets appropriate states for [Change] and [Custom] buttons
    def SetFirewallInterfacesCustomAndChangeButtons(current_item)
      # if called from Init() function
      if current_item == nil
        current_item = Convert.to_string(
          UI.QueryWidget(Id("table_firewall_interfaces"), :CurrentItem)
        )
      end

      # string is one of known network interfaces
      if Builtins.regexpmatch(current_item, "^known-.*")
        UI.ChangeWidget(Id("change_firewall_interface"), :Enabled, true)
        UI.ChangeWidget(Id("user_defined_firewall_interface"), :Enabled, true) 
        # string is a custom string
      else
        UI.ChangeWidget(Id("change_firewall_interface"), :Enabled, false)
        UI.ChangeWidget(Id("user_defined_firewall_interface"), :Enabled, true)
      end

      nil
    end

    # Function redraws Interfaces Table
    def RedrawFirewallInterfaces
      table_items = []

      # firstly listing all known interfaces
      Builtins.foreach(SuSEFirewall.GetAllKnownInterfaces) do |interface|
        # TRANSLATORS: table item, connected with firewall zone of interface
        zone_name = _("No zone assigned")
        if Ops.get(interface, "zone") != nil
          zone_name = SuSEFirewall.GetZoneFullName(Ops.get(interface, "zone"))
        end
        # shortening the network card name
        if Ops.get(interface, "name") != nil &&
            Ops.greater_than(
              Builtins.size(Ops.get(interface, "name", "")),
              @max_length_intname
            )
          Ops.set(
            interface,
            "name",
            Ops.add(
              Builtins.substring(
                Ops.get(interface, "name", ""),
                0,
                Ops.subtract(@max_length_intname, 3)
              ),
              "..."
            )
          )
        end
        table_items = Builtins.add(
          table_items,
          Item(
            Id(Ops.add("known-", Ops.get(interface, "id"))),
            Ops.get(interface, "name"),
            Ops.get(interface, "id"),
            zone_name
          )
        )
      end

      Builtins.foreach(SuSEFirewall.GetKnownFirewallZones) do |zone|
        specials = SuSEFirewall.GetSpecialInterfacesInZone(zone)
        zone_name = SuSEFirewall.GetZoneFullName(zone)
        custom_string_text = ""
        Builtins.foreach(specials) do |special|
          # TRANSLATORS: table item, "User defined string" instead of Device_name
          custom_string_text = _("Custom string")
          table_items = Builtins.add(
            table_items,
            Item(
              Id(Ops.add("special-", special)),
              custom_string_text,
              special,
              zone_name
            )
          )
        end
      end

      UI.ChangeWidget(Id("table_firewall_interfaces"), :Items, table_items)

      SetFirewallInterfacesCustomAndChangeButtons(nil)

      nil
    end

    # Function initializes Interfaces table and known_device_names
    def InitFirewallInterfaces(key)
      SetFirewallIcon()

      # initializing names of interfaces
      @known_device_names = {}
      Builtins.foreach(SuSEFirewall.GetAllKnownInterfaces) do |known_interface|
        # shortening the network card name
        if Ops.greater_than(
            Builtins.size(Ops.get(known_interface, "name", "")),
            @max_length_intname
          )
          Ops.set(
            known_interface,
            "name",
            Ops.add(
              Builtins.substring(
                Ops.get(known_interface, "name", ""),
                0,
                Ops.subtract(@max_length_intname, 3)
              ),
              "..."
            )
          )
        end
        Ops.set(
          @known_device_names,
          Ops.get(known_interface, "id", ""),
          Ops.get(known_interface, "name", "")
        )
      end

      # known interfaces/string have ID: "known-" + interface
      # uknown strings have          ID: "special-" + string

      RedrawFirewallInterfaces()

      nil
    end

    # Function handles popup dialog witch setting Interface into Zone
    def HandlePopupSetFirewallInterfaceIntoZone(interface)
      # interface could be unassigned
      # TRANSLATORAS: selection box item, connected with firewall zone of interface
      zones = [Item(Id(""), _("No Zone Assigned"))]
      # current zone of interface
      current_zone = SuSEFirewall.GetZoneOfInterface(interface)
      Builtins.foreach(SuSEFirewall.GetKnownFirewallZones) do |zone_shortname|
        zones = Builtins.add(
          zones,
          Item(
            Id(zone_shortname),
            SuSEFirewall.GetZoneFullName(zone_shortname),
            zone_shortname == current_zone ? true : false
          )
        )
      end

      # opening popup
      UI.OpenDialog(
        @all_popup_definition,
        SetFirewallInterfaceIntoZone(
          Ops.get(@known_device_names, interface, ""),
          interface,
          zones
        )
      )

      ret = Convert.to_string(UI.UserInput)

      changed = false
      if ret == "ok"
        new_zone = Convert.to_string(
          UI.QueryWidget(Id("zone_for_interface"), :Value)
        )
        if new_zone != current_zone
          changed = true
          SuSEFirewall.AddInterfaceIntoZone(interface, new_zone)
        end
      end

      UI.CloseDialog

      RedrawFirewallInterfaces() if changed

      nil
    end

    # Function handles popup with additional settings in zones
    def HandlePopupAdditionalSettingsForZones
      starting_additionals = {}
      zones_additons = {}

      Builtins.foreach(SuSEFirewall.GetKnownFirewallZones) do |zone_shortname|
        specials = SuSEFirewall.GetSpecialInterfacesInZone(zone_shortname)
        Ops.set(starting_additionals, zone_shortname, specials)
        Ops.set(
          zones_additons,
          zone_shortname,
          {
            "name"  => SuSEFirewall.GetZoneFullName(zone_shortname),
            "items" => Builtins.mergestring(specials, " ")
          }
        )
      end

      UI.OpenDialog(
        @all_popup_definition,
        AdditionalSettingsForZones(zones_additons)
      )

      ret = Convert.to_string(UI.UserInput)

      changed = false
      if ret == "ok"
        events_remove = []
        events_add = []
        Builtins.foreach(SuSEFirewall.GetKnownFirewallZones) do |zone_shortname|
          new_additions = Builtins.splitstring(
            Convert.to_string(
              UI.QueryWidget(
                Id(Ops.add("zone_additions_", zone_shortname)),
                :Value
              )
            ),
            " "
          )
          # checking for new additions
          Builtins.foreach(new_additions) do |new_addition_item|
            if new_addition_item != "" &&
                !Builtins.contains(
                  Ops.get(starting_additionals, zone_shortname, []),
                  new_addition_item
                )
              changed = true
              events_add = Builtins.add(
                events_add,
                [new_addition_item, zone_shortname]
              )
            end
          end
          # checking for removed additions
          Builtins.foreach(Ops.get(starting_additionals, zone_shortname, [])) do |old_addition_item|
            if old_addition_item != "" &&
                !Builtins.contains(new_additions, old_addition_item)
              changed = true
              events_remove = Builtins.add(
                events_remove,
                [old_addition_item, zone_shortname]
              )
            end
          end
        end
        Builtins.foreach(events_add) do |adding|
          SuSEFirewall.AddSpecialInterfaceIntoZone(
            Ops.get(adding, 0, ""),
            Ops.get(adding, 1, "")
          )
        end
        Builtins.foreach(events_remove) do |removing|
          SuSEFirewall.RemoveSpecialInterfaceFromZone(
            Ops.get(removing, 0, ""),
            Ops.get(removing, 1, "")
          )
        end
      end

      UI.CloseDialog

      RedrawFirewallInterfaces() if changed

      nil
    end

    # Function handles whole firewall-interfaces dialg
    def HandleFirewallInterfaces(key, event)
      event = deep_copy(event)
      ret = Ops.get(event, "ID")
      # "Activated" (double-click) or "SelectionChanged" (any other)
      event_reason = Ops.get_string(event, "EventReason", "SelectionChanged")

      current_item = Convert.to_string(
        UI.QueryWidget(Id("table_firewall_interfaces"), :CurrentItem)
      )

      # double click on the table item
      if ret == "table_firewall_interfaces" && event_reason == "Activated"
        # known iterface means -> as it was pressed [Change] button
        if Builtins.regexpmatch(current_item, "^known-")
          ret = "change_firewall_interface" 
          # known iterface means -> as it was pressed [Custom] button
        elsif Builtins.regexpmatch(current_item, "^special-")
          ret = "user_defined_firewall_interface"
        end
      end

      # Double click on the item or some modification button has been pressed
      if ret == "change_firewall_interface" ||
          ret == "user_defined_firewall_interface"
        # "change" can handle both interfaces and special strings
        if ret == "change_firewall_interface"
          # handling interfaces
          if Builtins.regexpmatch(current_item, "^known-")
            HandlePopupSetFirewallInterfaceIntoZone(
              Builtins.regexpsub(current_item, "^known-(.*)", "\\1")
            ) 
            # handling special strings
          elsif Builtins.regexpmatch(current_item, "^special-")
            HandlePopupAdditionalSettingsForZones()
          else
            Builtins.y2error("Uknown interfaces_item '%1'", current_item)
          end 
          # "user-defined" can only handle special strings
        elsif ret == "user_defined_firewall_interface"
          HandlePopupAdditionalSettingsForZones()
        end 
        # single click (changed current item)
      elsif ret == "table_firewall_interfaces" &&
          event_reason == "SelectionChanged"
        SetFirewallInterfacesCustomAndChangeButtons(current_item)
      end

      nil
    end

    # Reports that the port definition is wrong. Either a single port
    # or a port range. Returns whether user accepts the wrong port definition
    # despite this warning.
    #
    # @param [String] port_nr
    # @param [String] port_definition might be a single port or a port-range definition
    # @return [Boolean] whether user accepts the port definition despite the warning.
    #
    # @example
    #	// maximum port number is 65535, port range
    #	boolean accepted = ReportWrongPortDefinition(99999, "5:99999");
    #	// dtto., single port
    #	boolean whattodo = ReportWrongPortDefinition(78910, "78910");
    def ReportWrongPortDefinition(port_nr, port_definition)
      port_err = ""

      if port_nr == port_definition
        # TRANSLATORS: error message, %1 stands for the port number
        port_err = Builtins.sformat(_("Port number %1 is invalid."), port_nr)
      else
        # TRANSLATORS: error message, %1 stands for the port number,
        # %2 stands for, e.g., port range, where the wrong port definition %1 was found
        port_err = Builtins.sformat(
          _("Port number %1 in definition %2 is invalid."),
          port_nr,
          port_definition
        )
      end

      Popup.ContinueCancelHeadline(
        # TRANSLATORS: popup headline
        _("Invalid Port Definition"),
        Ops.add(
          Ops.add(port_err, "\n\n"),
          # TRANSLATORS: popup message, %1 stands for the maximal port number
          # that is possible to use in port-range
          Builtins.sformat(
            _(
              "The port number must be in the interval from 1 to %1 (inclusive)."
            ),
            SuSEFirewall.max_port_number
          )
        )
      )
    end

    def CheckPortNumberDefinition(port_nr, port)
      if Ops.less_than(port_nr, 1) ||
          Ops.greater_than(port_nr, SuSEFirewall.max_port_number)
        return ReportWrongPortDefinition(Builtins.tostring(port_nr), port)
      else
        return true
      end
    end

    def CheckPortNameDefinition(port_name)
      if PortAliases.IsAllowedPortName(port_name)
        return true
      else
        Report.Error(PortAliases.AllowedPortNameOrNumber)
        return false
      end
    end

    # Function checks list of ports if they exist (are known).
    #
    # @param [Object] ui_id for the setfocus
    # @param list <string> of ports to be checked
    def CheckIfTheyAreAllKnownPorts(ui_id, ports)
      ui_id = deep_copy(ui_id)
      ports = deep_copy(ports)
      checked = true

      # begin of for~each
      Builtins.foreach(ports) do |port|
        # previos port was wrong, break the loop
        raise Break if !checked
        # just a waste-space
        next if port == ""
        # common numeric port
        if Builtins.regexpmatch(port, "^[0123456789]+$")
          port_nr = Builtins.tointeger(port)
          if CheckPortNumberDefinition(port_nr, port) && checked
            checked = true
          else
            checked = false
          end

          next
        end
        # common port range
        if Builtins.regexpmatch(port, "^[0123456789]+:[0123456789]+$")
          port1 = Builtins.regexpsub(
            port,
            "^([0123456789]+):[0123456789]+$",
            "\\1"
          )
          port2 = Builtins.regexpsub(
            port,
            "^[0123456789]+:([0123456789]+)$",
            "\\1"
          )

          port1i = Builtins.tointeger(port1)
          port2i = Builtins.tointeger(port2)

          checked = false if !CheckPortNumberDefinition(port1i, port)

          if !CheckPortNumberDefinition(port2i, port)
            checked = false
          # port range is defined as 'A:B' where A<B
          elsif port1i != nil && port2i != nil && Ops.less_than(port1i, port2i)
            next
          elsif !Popup.ContinueCancelHeadline(
              # TRANSLATORS: popup headline
              _("Invalid Port Range Definition"),
              # TRANSLATORS: popup message, %1 is a port-range defined by user
              Builtins.sformat(
                _(
                  "Port range %1 is invalid.\n" +
                    "It must be defined as the min_port_number:max_port_number and\n" +
                    "max_port_number must be bigger than min_port_number."
                ),
                port
              )
            ) && checked
            checked = false
          end

          next
        end
        # port number
        if !PortAliases.IsKnownPortName(port)
          if !Popup.ContinueCancelHeadline(
              # TRANSLATORS: popup headline
              _("Unknown Port Name"),
              Builtins.sformat(
                # TRANSLATORS: popup message, %1 is a port-name
                _(
                  "Port name %1 is unknown in your current system.\n" +
                    "It probably would not work.\n" +
                    "Really use this port?\n"
                ),
                port
              )
            )
            checked = false
          end

          next
        end # end of for~each
      end

      UI.SetFocus(Id(ui_id)) if !checked

      checked
    end

    # Checks the string (services definition) for syntax errors
    #
    # @param [String] services_definition
    # @return [Boolean] whether everything was ok or whether user wants is despite the error
    def CheckAdditionalServicesDefinition(services_definition)
      if Builtins.regexpmatch(services_definition, ",")
        ports = Builtins.splitstring(services_definition, ",")
        return Popup.YesNoHeadline(
          # TRANSLATORS: popup headline
          _("Invalid Additional Service Definition"),
          # TRANSLATORS: popup message, %1 stands for the wrong settings (might be quite long)
          Builtins.sformat(
            _(
              "It appears that the additional service settings\n" +
                "%1\n" +
                "are wrong. Entries should be separated by spaces instead of commas,\n" +
                "which are not allowed.\n" +
                "Really use the current settings?"
            ),
            services_definition
          )
        )
      end

      true
    end

    def HandlePopupAdditionalServices(zone)
      zone_name = SuSEFirewall.GetZoneFullName(zone)

      UI.OpenDialog(@all_popup_definition, AdditionalServices(zone_name))

      # getting additional services
      additional_tcp = Builtins.toset(
        SuSEFirewall.GetAdditionalServices("TCP", zone)
      )
      additional_udp = Builtins.toset(
        SuSEFirewall.GetAdditionalServices("UDP", zone)
      )
      additional_rpc = Builtins.toset(
        SuSEFirewall.GetAdditionalServices("RPC", zone)
      )
      additional_ip = Builtins.toset(
        SuSEFirewall.GetAdditionalServices("IP", zone)
      )

      # filling up popup dialog
      UI.ChangeWidget(
        Id("additional_tcp"),
        :Value,
        Builtins.mergestring(additional_tcp, " ")
      )
      UI.ChangeWidget(
        Id("additional_udp"),
        :Value,
        Builtins.mergestring(additional_udp, " ")
      )
      UI.ChangeWidget(
        Id("additional_rpc"),
        :Value,
        Builtins.mergestring(additional_rpc, " ")
      )
      UI.ChangeWidget(
        Id("additional_ip"),
        :Value,
        Builtins.mergestring(additional_ip, " ")
      )

      # Filling up help
      UI.ChangeWidget(:help_text, :Value, HelpForDialog("additional-services"))

      ret = nil
      ret_value = false
      while true
        ret = UI.UserInput

        if ret == "ok"
          s_additional_tcp = Convert.to_string(
            UI.QueryWidget(Id("additional_tcp"), :Value)
          )
          new_additional_tcp = Builtins.toset(
            Builtins.splitstring(s_additional_tcp, " ")
          )

          s_additional_udp = Convert.to_string(
            UI.QueryWidget(Id("additional_udp"), :Value)
          )
          new_additional_udp = Builtins.toset(
            Builtins.splitstring(s_additional_udp, " ")
          )

          s_additional_rpc = Convert.to_string(
            UI.QueryWidget(Id("additional_rpc"), :Value)
          )
          new_additional_rpc = Builtins.toset(
            Builtins.splitstring(s_additional_rpc, " ")
          )

          s_additional_ip = Convert.to_string(
            UI.QueryWidget(Id("additional_ip"), :Value)
          )
          new_additional_ip = Builtins.toset(
            Builtins.splitstring(s_additional_ip, " ")
          )

          # Check the format
          next if !CheckAdditionalServicesDefinition(s_additional_tcp)
          next if !CheckAdditionalServicesDefinition(s_additional_udp)
          next if !CheckAdditionalServicesDefinition(s_additional_rpc)
          next if !CheckAdditionalServicesDefinition(s_additional_ip)

          # checking for known TCP and UDP port names
          if !CheckIfTheyAreAllKnownPorts("additional_tcp", new_additional_tcp)
            next
          end
          if !CheckIfTheyAreAllKnownPorts("additional_udp", new_additional_udp)
            next
          end

          SuSEFirewall.SetAdditionalServices("TCP", zone, new_additional_tcp)
          SuSEFirewall.SetAdditionalServices("UDP", zone, new_additional_udp)
          SuSEFirewall.SetAdditionalServices("RPC", zone, new_additional_rpc)
          SuSEFirewall.SetAdditionalServices("IP", zone, new_additional_ip)

          ret_value = true
          break
        elsif ret == "cancel" || ret == :cancel
          ret_value = false
          break
        end
      end

      UI.CloseDialog
      ret_value
    end

    def RedrawAllowedServicesDialog(current_zone)
      if SuSEFirewall.GetProtectFromInternalZone == false &&
          current_zone == "INT"
        UI.ChangeWidget(Id("allow_service_names"), :Enabled, false)
        UI.ChangeWidget(Id("add_allowed_service"), :Enabled, false)
        UI.ChangeWidget(Id("table_allowed_services"), :Enabled, false)
        UI.ChangeWidget(Id("remove_allowed_service"), :Enabled, false)
        UI.ChangeWidget(Id("advanced_allowed_service"), :Enabled, false)
      else
        UI.ChangeWidget(Id("allow_service_names"), :Enabled, true)
        UI.ChangeWidget(Id("add_allowed_service"), :Enabled, true)
        UI.ChangeWidget(Id("table_allowed_services"), :Enabled, true)
        UI.ChangeWidget(Id("remove_allowed_service"), :Enabled, true)
        UI.ChangeWidget(Id("advanced_allowed_service"), :Enabled, true)
      end

      nil
    end

    def RedrawAllowedServices(current_zone)
      if !Builtins.contains(SuSEFirewall.GetKnownFirewallZones, current_zone)
        Builtins.y2error("Unknown zone '%1'", current_zone)
        return nil
      end

      # FIXME: protect from internal, disabling table, etc...

      allowed_services = []
      # sorted by translated service_name
      translations_to_service_ids = {}

      Builtins.foreach(SuSEFirewallServices.GetSupportedServices) do |service_id, service_name|
        # a service with the very same name (translation) already defined
        if Ops.get(translations_to_service_ids, service_name) != nil
          # service:apache2 -> apache2
          if SuSEFirewallServices.ServiceDefinedByPackage(service_id)
            service_name = Builtins.sformat(
              "%1 (%2)",
              service_name,
              SuSEFirewallServices.GetFilenameFromServiceDefinedByPackage(
                service_id
              )
            )
          else
            service_name = Builtins.sformat("%1 (%2)", service_name, service_id)
          end
        end
        Ops.set(translations_to_service_ids, service_name, service_id)
      end

      all_known_services = GetDefinedServicesListedItems()
      not_allowed_services = []

      # not protected, all services are allowed
      if current_zone == "INT" && !SuSEFirewall.GetProtectFromInternalZone
        Builtins.foreach(translations_to_service_ids) do |service_name, service_id|
          allowed_services = Builtins.add(
            allowed_services,
            Item(Id(service_id), service_name)
          )
        end 
        # protected, only allowed services
      else
        Builtins.foreach(translations_to_service_ids) do |service_name, service_id|
          if SuSEFirewall.IsServiceSupportedInZone(service_id, current_zone)
            allowed_services = Builtins.add(
              allowed_services,
              Item(
                Id(service_id),
                service_name,
                SuSEFirewallServices.GetDescription(service_id)
              )
            )
          else
            not_allowed_services = Builtins.add(
              not_allowed_services,
              Item(Id(service_id), service_name)
            )
          end
        end
      end

      # BNC #461790: A better sorting
      allowed_services = Builtins.sort(allowed_services) do |x, y|
        Ops.less_or_equal(
          Builtins.tolower(Ops.get_string(x, 1, "a")),
          Builtins.tolower(Ops.get_string(y, 1, "b"))
        )
      end
      not_allowed_services = Builtins.sort(not_allowed_services) do |x, y|
        Ops.less_or_equal(
          Builtins.tolower(Ops.get_string(x, 1, "a")),
          Builtins.tolower(Ops.get_string(y, 1, "b"))
        )
      end

      UI.ChangeWidget(Id("table_allowed_services"), :Items, allowed_services)
      UI.ReplaceWidget(
        Id("allow_service_names_replacepoint"),
        # TRANSLATORS: select box
        ComboBox(
          Id("allow_service_names"),
          _("&Service to Allow"),
          not_allowed_services
        )
      )

      # disable or enable buttons, selectboxes, table
      RedrawAllowedServicesDialog(current_zone)

      if Builtins.size(allowed_services) == 0
        UI.ChangeWidget(Id("remove_allowed_service"), :Enabled, false)
      end

      nil
    end

    def InitAllowedServices(key)
      SetFirewallIcon()

      if SuSEFirewall.GetProtectFromInternalZone
        UI.ChangeWidget(Id("protect_from_internal"), :Value, true)
      else
        UI.ChangeWidget(Id("protect_from_internal"), :Value, false)
      end

      # The default zone
      init_zone = "EXT"

      # All zones
      all_currently_known_zones = SuSEFirewall.GetKnownFirewallZones

      # The default zone must exist in configuration
      if !Builtins.contains(all_currently_known_zones, init_zone)
        init_zone = Ops.get(all_currently_known_zones, 0)
      end
      # Checking
      if init_zone == nil
        Builtins.y2error("There are no zones defined!")
        return
      end

      RedrawAllowedServices(init_zone)
      UI.ChangeWidget(Id("allowed_services_zone"), :Value, init_zone)

      nil
    end

    def HandleAllowedServices(key, event)
      event = deep_copy(event)
      ret = Ops.get(event, "ID")

      current_zone = Convert.to_string(
        UI.QueryWidget(Id("allowed_services_zone"), :Value)
      )

      # changing zone
      if ret == "allowed_services_zone"
        RedrawAllowedServices(current_zone)
      elsif ret == "protect_from_internal"
        protect_from_internal = Convert.to_boolean(
          UI.QueryWidget(Id("protect_from_internal"), :Value)
        )
        SuSEFirewall.SetProtectFromInternalZone(protect_from_internal)
        RedrawAllowedServices(current_zone)
      elsif ret == "add_allowed_service"
        add_service = Convert.to_string(
          UI.QueryWidget(Id("allow_service_names"), :Value)
        )
        SuSEFirewall.SetServicesForZones([add_service], [current_zone], true)
        RedrawAllowedServices(current_zone)
      elsif ret == "remove_allowed_service"
        if Confirm.DeleteSelected
          remove_service = Convert.to_string(
            UI.QueryWidget(Id("table_allowed_services"), :CurrentItem)
          )
          SuSEFirewall.SetServicesForZones(
            [remove_service],
            [current_zone],
            false
          )
          RedrawAllowedServices(current_zone)
        end
      elsif ret == "advanced_allowed_service"
        # redraw when "OK" button pressed
        if HandlePopupAdditionalServices(current_zone)
          RedrawAllowedServices(current_zone)
        end
      end

      nil
    end

    # Function sets UI for Masquerade Table (and buttons) enabled or disabled
    #
    # @param	boolean enable
    def SetMasqueradeTableUsable(usable)
      UI.ChangeWidget(Id("table_redirect_masq"), :Enabled, usable)
      UI.ChangeWidget(Id("add_redirect_to_masquerade"), :Enabled, usable)
      UI.ChangeWidget(Id("remove_redirect_to_masquerade"), :Enabled, usable)

      nil
    end

    # Function returns if masquerading is possible.
    # Masquerading needs at least two interfaces in two different firewall zones.
    # One of them has to be External.
    #
    # @return	[Boolean] if possible.
    def IsMasqueradingPossible
      # FIXME: for Expert configuration, there is possible to set the masqueraded zone
      #        it is EXT for Simple configuration as default
      possible = false

      # if (!IsThisExpertConfiguration()) {
      # needs to have any external and any other interface
      has_external = false
      has_other = false

      Builtins.foreach(SuSEFirewall.GetKnownFirewallZones) do |zone|
        # no interfaces in zone
        if Builtins.size(
            Builtins.union(
              SuSEFirewall.GetInterfacesInZone(zone),
              SuSEFirewall.GetSpecialInterfacesInZone(zone)
            )
          ) == 0
          next
        end
        if zone == "EXT"
          has_external = true
        else
          has_other = true
        end
      end

      possible = has_external && has_other
      # } else {
      #    y2error("FIXME: missing functionality for expert configuration");
      #}

      possible
    end

    def InitMasquerading(key)
      SetFirewallIcon()

      masquerade = SuSEFirewall.GetMasquerade
      masquerade_possible = IsMasqueradingPossible()

      # setting checkbox
      UI.ChangeWidget(Id("masquerade_networks"), :Value, masquerade)

      # enabling or disabling masquerade redirect table when masquerading is enabled
      # and also possible
      #if (!IsThisExpertConfiguration()) {
      SetMasqueradeTableUsable(masquerade && masquerade_possible)
      #}

      # impossible masquerading, user gets information why
      if !masquerade_possible
        # disabling checkbox
        UI.ChangeWidget(Id("masquerade_networks"), :Enabled, false)

        UI.ReplaceWidget(
          Id("replacepoint_masquerade_information"), #:
          #`Left(`Label("FIXME: missing functionality for expert configuration"))
          #)
          #(!IsThisExpertConfiguration() ?
          # TRANSLATORS: informative label
          Left(
            Label(
              _(
                "Masquerading needs at least one external interface and one other interface."
              )
            )
          )
        )
      end

      nil
    end

    # Validates existency of a value in a referenced UI entry
    # and reports error otherwise
    #
    # @param any UI id
    # @report boolean if value exists
    def ValidateExistency(ui_id)
      ui_id = deep_copy(ui_id)
      if UI.QueryWidget(Id(ui_id), :Value) == ""
        UI.SetFocus(Id(ui_id))
        # TRANSLATORS: popup message
        Popup.Error(_("This entry must be completed."))
        return false
      end
      true
    end

    # Checks whether the referenced UI entry contains a valid
    # port definition and reports an error otherwise
    #
    # @param any UI id
    # @return [Boolean] if entry is valid
    def ValidatePortEntry(ui_id)
      ui_id = deep_copy(ui_id)
      port = Convert.to_string(UI.QueryWidget(Id(ui_id), :Value))

      # no port can be allowed
      return true if port == ""

      # checking for port-name rightness
      if !PortAliases.IsAllowedPortName(port)
        UI.SetFocus(Id(ui_id))
        Popup.Error(
          Ops.add(
            # TRANSLATORS: popup message, right port definition is two lines below this message
            _("Wrong port definition.") + "\n\n",
            PortAliases.AllowedPortNameOrNumber
          )
        )
        return false
      end

      # checking for known TCP and UDP port names
      return false if !CheckIfTheyAreAllKnownPorts(ui_id, [port])

      true
    end

    # Function checks port number got as parameter.
    # If check fails SetFocus is called and an empty string is returned.
    #
    # @param any UI id
    # @return [Fixnum] port number (or nil)
    def GetPortNumber(ui_id)
      ui_id = deep_copy(ui_id)
      port_to_be_checked = Convert.to_string(UI.QueryWidget(Id(ui_id), :Value))
      port_number = PortAliases.GetPortNumber(port_to_be_checked)

      # if port name wasn't found
      if port_number == nil
        Popup.Error(
          # TRANSLATORS: popup error message
          _(
            "Wrong port definition.\n" +
              "No port number found for this port name.\n" +
              "Use the port number instead of the port name.\n"
          )
        )

        # setfocus for GUI
        UI.SetFocus(Id(ui_id)) if ui_id != "" && ui_id != nil
      end

      port_number
    end

    # Checks whether the referenced UI entry contains a valid IPv4 or v6
    # and reports error otherwise.
    #
    # @param any UI id
    # @return [Boolean] whether it's valid IP
    def ValidateIPEntry(ui_id)
      ui_id = deep_copy(ui_id)
      ip = Convert.to_string(UI.QueryWidget(Id(ui_id), :Value))
      if !IP.Check(ip)
        UI.SetFocus(Id(ui_id))
        Popup.Error(
          Ops.add(
            Ops.add(
              Ops.add(
                # TRANSLATORS: popup message, right definition is two lines below this message
                _("Invalid IP definition.") + "\n\n",
                IP.Valid4
              ),
              "\n"
            ),
            IP.Valid6
          )
        )
        return false
      end
      true
    end

    def UserReadablePortName(port, protocol)
      return "" if port == ""
      return nil if port == nil

      protocol = Builtins.tolower(protocol)
      # Do not seek port number for RPC services
      return port if protocol == "rpc" || protocol == "_rpc_"

      # number
      if Builtins.regexpmatch(port, "^[0123456789]+$")
        port_name = GetPortName(port)
        # port name must be known and not the same as defined yet
        if port_name != nil && port_name != port
          port = Builtins.sformat("%1 (%2)", port_name, port)
        end 
        # not a port range
      elsif !Builtins.regexpmatch(port, "^[0123456789]+:[0123456789]+$")
        port_number = PortAliases.GetPortNumber(port)
        if port_number != nil && Builtins.tostring(port_number) != port
          port = Builtins.sformat("%1 (%2)", port, port_number)
        end
      end

      port
    end

    def RedrawRedirectToMasqueradedIPTable
      items = []

      row_id = 0
      Builtins.foreach(SuSEFirewall.GetListOfForwardsIntoMasquerade) do |rule|
        # redirect_to_port is the same as requested_port if not defined
        if Ops.get(rule, "to_port", "") == ""
          Ops.set(rule, "to_port", Ops.get(rule, "req_port", ""))
        end
        # printing port names rather then port numbers
        Builtins.foreach(["req_port", "to_port"]) do |key|
          Ops.set(
            rule,
            key,
            UserReadablePortName(
              Ops.get(rule, key, ""),
              Ops.get(rule, "protocol", "")
            )
          )
        end
        items = Builtins.add(
          items,
          Item(
            Id(row_id),
            Ops.get(rule, "source_net", ""),
            Ops.get(rule, "protocol", ""),
            Ops.get(rule, "req_ip", ""),
            Ops.get(rule, "req_port", ""),
            UI.Glyph(:BulletArrowRight),
            Ops.get(rule, "forward_to", ""),
            Ops.get(rule, "to_port", "")
          )
        )
        row_id = Ops.add(row_id, 1)
      end

      UI.ChangeWidget(Id("table_redirect_masq"), :Items, items)

      nil
    end


    def HandlePopupAddRedirectToMasqueradedIPRule
      UI.OpenDialog(@all_popup_definition, AddRedirectToMasqueradedIPRule())
      UI.SetFocus(Id("add_source_network"))

      ret_value = false

      while true
        ret = UI.UserInput

        if ret == "cancel" || ret == :cancel
          break
        elsif ret == "ok"
          next if !ValidateExistency("add_requested_port")
          next if !ValidateExistency("add_source_network")
          next if !ValidateExistency("add_redirectto_ip")

          next if !ValidatePortEntry("add_requested_port")
          next if !ValidatePortEntry("add_redirectto_port")
          next if !ValidateIPEntry("add_redirectto_ip")

          # FIXME: checking for spaces in sttrings
          #        removing space from start or end of the string

          add_source_network = Convert.to_string(
            UI.QueryWidget(Id("add_source_network"), :Value)
          )
          add_requested_ip = Convert.to_string(
            UI.QueryWidget(Id("add_requested_ip"), :Value)
          )
          add_protocol = Convert.to_string(
            UI.QueryWidget(Id("add_protocol"), :Value)
          )
          add_requested_port = Convert.to_string(
            UI.QueryWidget(Id("add_requested_port"), :Value)
          )
          add_redirectto_ip = Convert.to_string(
            UI.QueryWidget(Id("add_redirectto_ip"), :Value)
          )
          add_redirectto_port = Convert.to_string(
            UI.QueryWidget(Id("add_redirectto_port"), :Value)
          )

          # Ports must be port numbers, getting port numbers from port names
          if add_requested_port != "" && add_requested_port != nil
            add_requested_port = Builtins.tostring(
              GetPortNumber("add_requested_port")
            )
            next if add_requested_port == nil
          end
          if add_redirectto_port != "" && add_redirectto_port != nil
            add_redirectto_port = Builtins.tostring(
              GetPortNumber("add_redirectto_port")
            )
            next if add_redirectto_port == nil
          end

          # Requested IP is optional
          next if add_requested_ip != "" && !ValidateIPEntry("add_requested_ip")

          SuSEFirewall.AddForwardIntoMasqueradeRule(
            add_source_network,
            add_redirectto_ip,
            add_protocol,
            add_requested_port,
            add_redirectto_port,
            add_requested_ip
          )

          ret_value = true
          break
        end
      end

      UI.CloseDialog

      RedrawRedirectToMasqueradedIPTable() if ret_value

      nil
    end

    def HandleMasquerading(key, event)
      event = deep_copy(event)
      ret = Ops.get(event, "ID")

      if ret == "masquerade_networks"
        masquerade = Convert.to_boolean(
          UI.QueryWidget(Id("masquerade_networks"), :Value)
        )
        SuSEFirewall.SetMasquerade(masquerade)
        # enabling or disabling masquerade redirect table when masquerade enabled
        #if (!IsThisExpertConfiguration()) {
        SetMasqueradeTableUsable(masquerade) 
        #}
      end

      nil
    end

    def HandleRedirectToMasqueradedIP(key, event)
      event = deep_copy(event)
      ret = Ops.get(event, "ID")

      if ret == "add_redirect_to_masquerade"
        HandlePopupAddRedirectToMasqueradedIPRule()
      elsif ret == "remove_redirect_to_masquerade"
        current_item = Convert.to_integer(
          UI.QueryWidget(Id("table_redirect_masq"), :CurrentItem)
        )
        if Confirm.DeleteSelected
          SuSEFirewall.RemoveForwardIntoMasqueradeRule(current_item)
          RedrawRedirectToMasqueradedIPTable()
        end
      end

      nil
    end

    def InitRedirectToMasqueradedIP(key)
      SetFirewallIcon()

      RedrawRedirectToMasqueradedIPTable()

      nil
    end

    def HandlePopupIPsecTrustAsZone
      UI.OpenDialog(@all_popup_definition, IPsecTrustAsZone())

      default_value = SuSEFirewall.GetTrustIPsecAs
      UI.ChangeWidget(Id("trust_ipsec_as"), :Value, default_value)

      ret = UI.UserInput

      if ret == "ok"
        new_value = Convert.to_string(
          UI.QueryWidget(Id("trust_ipsec_as"), :Value)
        )
        SuSEFirewall.SetTrustIPsecAs(new_value)
      end

      UI.CloseDialog

      nil
    end

    # IPsec support opens IPsec traffic from external zone
    def InitIPsecSupport(key)
      SetFirewallIcon()

      # FIXME: check whether such service exists
      supported = SuSEFirewall.IsServiceSupportedInZone("service:ipsec", "EXT")

      if supported == nil
        Builtins.y2error("No such service 'service:ipsec'")
        UI.ChangeWidget(Id("ispsec_support"), :Enabled, false)
      else
        UI.ChangeWidget(Id("ispsec_support"), :Enabled, true)
        UI.ChangeWidget(Id("ispsec_support"), :Value, supported)
      end

      nil
    end

    def HandleIPsecSupport(key, event)
      event = deep_copy(event)
      ret = Ops.get(event, "ID")

      HandlePopupIPsecTrustAsZone() if ret == "ipsec_details"

      nil
    end

    def StoreIPsecSupport(key, event)
      event = deep_copy(event)
      to_support = Convert.to_boolean(
        UI.QueryWidget(Id("ispsec_support"), :Value)
      )
      SuSEFirewall.SetServicesForZones(["ipsec"], ["EXT"], to_support)

      nil
    end

    def InitLoggingLevel(key)
      SetFirewallIcon()

      UI.ChangeWidget(
        Id("logging_ACCEPT"),
        :Value,
        SuSEFirewall.GetLoggingSettings("ACCEPT")
      )
      UI.ChangeWidget(
        Id("logging_DROP"),
        :Value,
        SuSEFirewall.GetLoggingSettings("DROP")
      )

      nil
    end

    def StoreLoggingLevel(key, event)
      event = deep_copy(event)
      SuSEFirewall.SetLoggingSettings(
        "ACCEPT",
        Convert.to_string(UI.QueryWidget(Id("logging_ACCEPT"), :Value))
      )
      SuSEFirewall.SetLoggingSettings(
        "DROP",
        Convert.to_string(UI.QueryWidget(Id("logging_DROP"), :Value))
      )

      nil
    end

    def InitBroadcastConfigurationSimple(key)
      SetFirewallIcon()

      replace_dialog = VBox()

      allowed_bcast_ports = SuSEFirewall.GetBroadcastAllowedPorts

      Builtins.foreach(SuSEFirewall.GetKnownFirewallZones) do |zone|
        zone_name = SuSEFirewall.GetZoneFullName(zone)
        ports_for_zone = Builtins.mergestring(
          Ops.get(allowed_bcast_ports, zone, []),
          " "
        )
        log_packets = SuSEFirewall.GetIgnoreLoggingBroadcast(zone) == "no"
        replace_dialog = Builtins.add(
          replace_dialog,
          HBox(
            HWeight(
              40,
              InputField(
                Id(Ops.add("bcast_ports_", zone)),
                Opt(:hstretch),
                zone_name,
                ports_for_zone
              )
            ),
            HWeight(
              60,
              VBox(
                Label(""),
                # TRANSLATORS: check box
                CheckBox(
                  Id(Ops.add("bcast_log_", zone)),
                  _("&Log Not Accepted Broadcast Packets"),
                  log_packets
                )
              )
            )
          )
        )
      end

      UI.ReplaceWidget(Id("replace_point_bcast"), replace_dialog)

      nil
    end

    # FIXME: should check for PortAliases::IsKnownPortName() in future
    def StoreBroadcastConfigurationSimple(key, event)
      event = deep_copy(event)
      allowed_bcast_ports = {}

      Builtins.foreach(SuSEFirewall.GetKnownFirewallZones) do |zone|
        allowed_ports = Builtins.splitstring(
          Convert.to_string(
            UI.QueryWidget(Id(Ops.add("bcast_ports_", zone)), :Value)
          ),
          " "
        )
        log_packets = Convert.to_boolean(
          UI.QueryWidget(Id(Ops.add("bcast_log_", zone)), :Value)
        )
        Ops.set(allowed_bcast_ports, zone, allowed_ports)
        SuSEFirewall.SetIgnoreLoggingBroadcast(zone, log_packets ? "no" : "yes")
      end

      SuSEFirewall.SetBroadcastAllowedPorts(allowed_bcast_ports)

      nil
    end

    def InitServiceStartVsStartedStopped(key)
      @firewall_enabled_st = SuSEFirewall.GetEnableService
      @firewall_started_st = SuSEFirewall.IsStarted

      nil
    end

    def SetEnableFirewall(new_state)
      if @firewall_enabled_st == new_state
        Builtins.y2milestone(
          "Enable firewall status preserved (enable=%1)",
          @firewall_enabled_st
        )
        return
      end

      curr_running = SuSEFirewall.IsStarted
      new_running = new_state

      # disabling firewall
      if new_state == false && curr_running == true
        # TRANSLATORS: popup question
        if Popup.YesNo(
            _(
              "Firewall automatic starting has been disabled\n" +
                "but firewall is currently running.\n" +
                "\n" +
                "Stop the firewall after the new configuration has been written?\n"
            )
          )
          Builtins.y2milestone(
            "User decided to stop the firewall after it is disabled"
          )
          new_running = false
        else
          Builtins.y2milestone(
            "User decided not to stop the firewall after it is disabled"
          )
          new_running = true
        end
      end

      # Changes the default values - Enable and Start at once
      SuSEFirewall.SetEnableService(new_state)
      SuSEFirewall.SetStartService(new_running)

      Builtins.y2milestone(
        "New Settings - Firewall Enabled: %1, Firewall Started: %2 (after Write())",
        SuSEFirewall.GetEnableService,
        SuSEFirewall.GetStartService
      )

      nil
    end

    def RedrawCustomRules(current_zone)
      if current_zone == nil ||
          !Builtins.contains(SuSEFirewall.GetKnownFirewallZones, current_zone)
        Builtins.y2error("Unknown zone '%1'", current_zone)
        return nil
      end

      rules = SuSEFirewallExpertRules.GetListOfAcceptRules(current_zone)

      # some rules are already defined
      if Ops.greater_than(Builtins.size(rules), 0)
        counter = -1
        items = Builtins.maplist(rules) do |one_rule|
          counter = Ops.add(counter, 1)
          Item(
            Id(counter),
            Ops.get(one_rule, "network", ""),
            SuSEFirewall.GetProtocolTranslatedName(
              Ops.get(one_rule, "protocol", "")
            ),
            UserReadablePortName(
              Ops.get(one_rule, "dport", ""),
              Ops.get(one_rule, "protocol", "")
            ),
            UserReadablePortName(Ops.get(one_rule, "sport", ""), ""),
            Ops.get(one_rule, "options", "")
          )
        end

        items = Builtins.sort(items) do |aa, bb|
          Ops.less_than(Ops.get_string(aa, 1, ""), Ops.get_string(bb, 1, ""))
        end

        UI.ChangeWidget(Id("custom_rules_table"), :Items, items)
        UI.ChangeWidget(Id("remove_custom_rule"), :Enabled, true) 

        # no rules defined
      else
        UI.ChangeWidget(Id("custom_rules_table"), :Items, [])
        UI.ChangeWidget(Id("remove_custom_rule"), :Enabled, false)
      end

      nil
    end

    def InitCustomRules(key)
      SetFirewallIcon()

      # set the default once, EXT is the first one
      if @customrules_current_zone == nil
        Builtins.foreach(
          Convert.convert(
            Builtins.union(SuSEFirewall.GetKnownFirewallZones, ["EXT"]),
            :from => "list",
            :to   => "list <string>"
          )
        ) do |one_zone|
          # at least one interface in the zone
          if Ops.greater_than(
              Builtins.size(
                SuSEFirewall.GetInterfacesInZoneSupportingAnyFeature(one_zone)
              ),
              0
            )
            @customrules_current_zone = one_zone
          end
        end
        # nothing found, set the default manually
        @customrules_current_zone = "EXT" if @customrules_current_zone == nil
      end

      UI.ChangeWidget(
        Id("custom_rules_firewall_zone"),
        :Value,
        @customrules_current_zone
      )

      RedrawCustomRules(@customrules_current_zone)

      nil
    end

    def DeleteSelectedCustomRule(selected_zone, current_item)
      if SuSEFirewallExpertRules.DeleteRuleID(selected_zone, current_item)
        RedrawCustomRules(selected_zone)
        UI.ChangeWidget(Id("custom_rules_table"), :SelectedItem, 0)
      end

      nil
    end

    def CheckPortNameOrNumber(port)
      # port number
      if Builtins.regexpmatch(port, "^[0123456789]+$")
        return CheckPortNumberDefinition(Builtins.tointeger(port), port) 
        # not a port range
      elsif !Builtins.regexpmatch(port, "^[0123456789]+:[0123456789]+$")
        return CheckPortNameDefinition(port)
      end

      nil
    end

    def HandlePopupAddCustomRule(selected_zone)
      UI.OpenDialog(
        @all_popup_definition,
        HBox(
          MinWidth(30, RichText(HelpForDialog("custom-rules-popup"))),
          AddCustomFirewallRule()
        )
      )
      UI.SetFocus(Id("add_source_network"))

      ret_value = false

      while true
        ret = UI.UserInput

        if ret == "cancel" || ret == :cancel
          break
        elsif ret == "ok"
          next if !ValidateExistency("add_source_network")
          next if !ValidateExistency("add_protocol")

          add_source_network = Convert.to_string(
            UI.QueryWidget(Id("add_source_network"), :Value)
          )
          add_protocol = Convert.to_string(
            UI.QueryWidget(Id("add_protocol"), :Value)
          )
          add_destination_port = Convert.to_string(
            UI.QueryWidget(Id("add_destination_port"), :Value)
          )
          add_source_port = Convert.to_string(
            UI.QueryWidget(Id("add_source_port"), :Value)
          )
          add_options = Convert.to_string(
            UI.QueryWidget(Id("add_options"), :Value)
          )

          # network is mandatory
          if add_source_network == "" || !IP.CheckNetwork(add_source_network)
            UI.SetFocus(Id("add_source_network"))
            Report.Error(
              Ops.add(
                Ops.add(
                  Builtins.sformat(
                    _("Invalid network definition '%1'"),
                    add_source_network
                  ),
                  "\n"
                ),
                IP.ValidNetwork
              )
            )
            next
          end

          # destination port is optional
          if add_destination_port != ""
            if PortRanges.IsPortRange(add_destination_port)
              if !PortRanges.IsValidPortRange(add_destination_port)
                UI.SetFocus(Id("add_destination_port"))
                Report.Error(
                  Builtins.sformat(
                    _("Invalid port range '%1'"),
                    add_destination_port
                  )
                )
                next
              end
            elsif !CheckPortNameOrNumber(add_destination_port)
              UI.SetFocus(Id("add_destination_port"))
              Report.Error(
                Ops.add(
                  Ops.add(
                    Builtins.sformat(
                      _("Invalid port name or number '%1'"),
                      add_destination_port
                    ),
                    "\n"
                  ),
                  PortAliases.AllowedPortNameOrNumber
                )
              )
              next
            end
          end

          # source port is optional
          if add_source_port != ""
            if PortRanges.IsPortRange(add_source_port)
              if !PortRanges.IsValidPortRange(add_source_port)
                UI.SetFocus(Id("add_source_port"))
                Report.Error(
                  Builtins.sformat(
                    _("Invalid port range '%1'"),
                    add_source_port
                  )
                )
                next
              end
            elsif !CheckPortNameOrNumber(add_source_port)
              UI.SetFocus(Id("add_source_port"))
              Report.Error(
                Ops.add(
                  Ops.add(
                    Builtins.sformat(
                      _("Invalid port name or number '%1'"),
                      add_source_port
                    ),
                    "\n"
                  ),
                  PortAliases.AllowedPortNameOrNumber
                )
              )
              next
            end
          end

          SuSEFirewallExpertRules.AddNewAcceptRule(
            selected_zone,
            {
              "network"  => add_source_network,
              "protocol" => add_protocol,
              "dport"    => add_destination_port,
              "sport"    => add_source_port,
              "options"  => add_options
            }
          )

          ret_value = true
          break
        end
      end

      UI.CloseDialog

      ret_value
    end

    def HandleCustomRules(key, event)
      event = deep_copy(event)
      ret = Ops.get(event, "ID")

      selected_zone = Convert.to_string(
        UI.QueryWidget(Id("custom_rules_firewall_zone"), :Value)
      )

      if ret == "custom_rules_firewall_zone"
        @customrules_current_zone = selected_zone
        RedrawCustomRules(selected_zone)
      elsif ret == "add_custom_rule"
        if HandlePopupAddCustomRule(selected_zone)
          RedrawCustomRules(selected_zone)
        end
      elsif ret == "remove_custom_rule"
        current_item = Convert.to_integer(
          UI.QueryWidget(Id("custom_rules_table"), :CurrentItem)
        )

        if current_item != nil && Confirm.DeleteSelected
          DeleteSelectedCustomRule(selected_zone, current_item)
        end
      end

      nil
    end

    def GetBcastServiceName(protocol, sport)
      if protocol == "udp" && sport == ""
        return _("All services using UDP")
      elsif protocol == "tcp" && sport == ""
        return _("All services using TCP")
      elsif protocol == "udp" && PortAliases.GetPortNumber(sport) == 137
        return _("Samba browsing")
      elsif protocol == "udp" && PortAliases.GetPortNumber(sport) == 427
        return _("SLP browsing")
      else
        return Builtins.sformat(
          "%1/%2",
          SuSEFirewall.GetProtocolTranslatedName(protocol),
          sport
        )
      end
    end

    def GetBcastNetworkName(network)
      if network == "0/0"
        return _("All networks")
      else
        return Builtins.sformat(_("Subnet: %1"), network)
      end
    end

    def RedrawBroadcastReplyTable
      items = []

      Builtins.foreach(SuSEFirewall.GetKnownFirewallZones) do |zone|
        ruleset = SuSEFirewall.GetServicesAcceptRelated(zone)
        rule_in_ruleset = -1
        Builtins.foreach(ruleset) do |one_rule|
          rule_in_ruleset = Ops.add(rule_in_ruleset, 1)
          rulelist = Builtins.splitstring(one_rule, ",")
          items = Builtins.add(
            items,
            Item(
              Id(Builtins.sformat("%1 %2", zone, rule_in_ruleset)),
              SuSEFirewall.GetZoneFullName(zone),
              Builtins.sformat(
                GetBcastServiceName(
                  Ops.get(rulelist, 1, ""),
                  Ops.get(rulelist, 2, "")
                )
              ),
              GetBcastNetworkName(Ops.get(rulelist, 0, "0/0"))
            )
          )
        end
      end

      if UI.WidgetExists(Id("table_broadcastreply"))
        UI.ChangeWidget(Id("table_broadcastreply"), :Items, items)
      end

      if UI.WidgetExists(Id(:delete_br))
        UI.ChangeWidget(Id(:delete_br), :Enabled, Builtins.size(items) != 0)
      end

      nil
    end

    def InitBroadcastReply(key)
      RedrawBroadcastReplyTable()

      nil
    end

    def GetBcastServiceProtocol(service)
      Ops.get(@service_to_protocol, service, "")
    end

    def GetBcastServicePort(service)
      Ops.get(@service_to_port, service, "")
    end

    def ValidateBroadcastReplyRule(zone, network, service, protocol, port)
      return true if service != "user-defined"

      if !IP.CheckNetwork(network)
        UI.SetFocus(Id(:network))
        Report.Error(
          Ops.add(
            Ops.add(
              Builtins.sformat(_("Invalid network definition '%1'"), network),
              "\n"
            ),
            IP.ValidNetwork
          )
        )
        return false
      end

      if !PortAliases.IsAllowedPortName(port)
        UI.SetFocus(Id(:port))
        Report.Error(
          Ops.add(
            Ops.add(
              Builtins.sformat(_("Invalid port name or number '%1'"), port),
              "\n"
            ),
            PortAliases.AllowedPortNameOrNumber
          )
        )
        return false
      end

      true
    end

    def AddAcceptBroadcastReplyRule
      zones = []
      Builtins.foreach(SuSEFirewall.GetKnownFirewallZones) do |zone_shortname|
        zones = Builtins.add(
          zones,
          Item(
            Id(zone_shortname),
            SuSEFirewall.GetZoneFullName(zone_shortname),
            # hard-coded default
            zone_shortname == "EXT"
          )
        )
      end

      UI.OpenDialog(
        VBox(
          Left(ComboBox(Id(:zone), _("&Zone"), zones)),
          Left(
            MinWidth(
              18,
              ComboBox(Id(:network), Opt(:editable), _("&Network"), ["0/0"])
            )
          ),
          Left(
            ComboBox(
              Id(:service),
              Opt(:notify),
              _("&Service"),
              [
                Item(Id("samba"), GetBcastServiceName("udp", "137")),
                Item(Id("slp"), GetBcastServiceName("udp", "427")),
                Item(Id("all-udp"), GetBcastServiceName("udp", "")),
                Item(Id("all-tcp"), GetBcastServiceName("tcp", "")),
                Item(Id("user-defined"), _("User-defined service"))
              ]
            )
          ),
          HSquash(
            HBox(
              HWeight(
                1,
                ComboBox(
                  Id(:protocol),
                  Opt(:disabled),
                  _("&Protocol"),
                  [
                    Item(
                      Id("udp"),
                      SuSEFirewall.GetProtocolTranslatedName("udp"),
                      true
                    ),
                    Item(
                      Id("tcp"),
                      SuSEFirewall.GetProtocolTranslatedName("tcp")
                    )
                  ]
                )
              ),
              HWeight(1, InputField(Id(:port), Opt(:disabled), _("Po&rt"), ""))
            )
          ),
          VSpacing(1),
          ButtonBox(
            PushButton(
              Id(:ok),
              Opt(:okButton, :default, :key_F10),
              Label.AddButton
            ),
            PushButton(
              Id(:cancel),
              Opt(:cancelButton, :key_F9),
              Label.CancelButton
            )
          )
        )
      )

      dialog_ret = false
      while true
        ret = UI.UserInput

        if ret == :service
          custom_service = UI.QueryWidget(Id(:service), :Value) == "user-defined"
          UI.ChangeWidget(Id(:protocol), :Enabled, custom_service)
          UI.ChangeWidget(Id(:port), :Enabled, custom_service)
        elsif ret == :ok
          # read the current settings
          zone = Convert.to_string(UI.QueryWidget(Id(:zone), :Value))
          network = Convert.to_string(UI.QueryWidget(Id(:network), :Value))
          service = Convert.to_string(UI.QueryWidget(Id(:service), :Value))

          # use either pre-defined or user-defined
          protocol = service == "user-defined" ?
            Convert.to_string(UI.QueryWidget(Id(:protocol), :Value)) :
            GetBcastServiceProtocol(service)

          # use either pre-defined or user-defined
          port = service == "user-defined" ?
            Convert.to_string(UI.QueryWidget(Id(:port), :Value)) :
            GetBcastServicePort(service)

          if !ValidateBroadcastReplyRule(zone, network, service, protocol, port)
            next
          end

          # Add the rule if validation went fine
          items = SuSEFirewall.GetServicesAcceptRelated(zone)
          new_rule = Builtins.sformat("%1,%2", network, protocol)
          new_rule = Builtins.sformat("%1,%2", new_rule, port) if port != ""
          items = Builtins.add(items, new_rule)
          SuSEFirewall.SetServicesAcceptRelated(zone, items)

          # redraw table
          dialog_ret = true
          break
        else
          break
        end
      end

      UI.CloseDialog

      dialog_ret
    end

    def HandleBroadcastReply(key, event)
      event = deep_copy(event)
      ret = Ops.get(event, "ID")

      if ret == :add_br
        RedrawBroadcastReplyTable() if AddAcceptBroadcastReplyRule()
      elsif ret == :delete_br
        current_id = Convert.to_string(
          UI.QueryWidget(Id("table_broadcastreply"), :Value)
        )
        if current_id != nil && current_id != ""
          if Confirm.DeleteSelected
            item_to_delete = Builtins.splitstring(current_id, " ")
            items = SuSEFirewall.GetServicesAcceptRelated(
              Ops.get_string(item_to_delete, 0, "")
            )
            item_in_list = Builtins.tointeger(
              Ops.get_string(item_to_delete, 1, "-1")
            )
            Ops.set(items, item_in_list, nil)
            items = Builtins.filter(items) { |one_rule| one_rule != nil }
            SuSEFirewall.SetServicesAcceptRelated(
              Ops.get_string(item_to_delete, 0, ""),
              items
            )
            RedrawBroadcastReplyTable()
          end
        else
          Report.Error(_("Select an item to delete."))
        end
      end

      nil
    end
  end
end
