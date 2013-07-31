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
# File:        include/firewall/dialogs.ycp
# Package:     Configuration YaST2 Firewall
# Summary:     Configuration screens
# Authors:     Lukas Ocilka <locilka@suse.cz>
#
# $Id$
#
# Configuration dialogs divided into smaller logic groups.
# Both Expert and Simple.
module Yast
  module FirewallSubdialogsInclude
    def initialize_firewall_subdialogs(include_target)
      textdomain "firewall"

      Yast.import "Label"
      Yast.import "ProductFeatures"
      Yast.import "SuSEFirewallServices"
      Yast.import "SuSEFirewall"

      # UI VARIABLES AND FUNCTIONS
      @expert_ui = ProductFeatures.GetFeature("globals", "ui_mode") == "expert"
    end

    # Function returns if this UI is an Expert UI.
    #
    # @return	[Boolean] if is expert or not
    def IsThisExpertConfiguration
      @expert_ui
    end

    def GetZonesListedItems
      items = []

      zone_names_to_zones = {}

      Builtins.foreach(SuSEFirewall.GetKnownFirewallZones) do |zone_id|
        Ops.set(
          zone_names_to_zones,
          SuSEFirewall.GetZoneFullName(zone_id),
          zone_id
        )
      end

      Builtins.foreach(zone_names_to_zones) do |zone_name, zone_id|
        items = Builtins.add(items, Item(Id(zone_id), zone_name))
      end

      deep_copy(items)
    end

    # TERM FUNCTIONS, WHOLE DIALOGS OR FRAMES

    def FirewallInterfaces
      # Network Manager
      network_manager = Empty()
      #if (NetworkService::IsManaged()) network_manager = `Left (
      #    // TRANSLATORS: an informative text
      #    //              When using a Network Manager, Firewall cannot determine NM-handled network interfaces
      #    `Label (_("Interfaces controlled by NetworkManager are not listed."))
      #);

      dialog = Frame(
        # TRANSLATORS: Frame label
        _("Firewall Interfaces"),
        VBox(
          network_manager,
          Table(
            Id("table_firewall_interfaces"),
            Opt(:notify, :immediate),
            Header(
              # TRANSLATORS: table header item
              _("Device"),
              # TRANSLATORS: table header item
              _("Interface or String"),
              # TRANSLATORS: table header item
              _("Configured In")
            ),
            []
          ),
          HBox(
            # TRANSLATORS: push button
            PushButton(
              Id("change_firewall_interface"),
              Opt(:key_F4),
              _("&Change...")
            ),
            # TRANSLATORS: push button
            PushButton(
              Id("user_defined_firewall_interface"),
              Opt(:key_F7),
              _("C&ustom...")
            ),
            HStretch()
          )
        )
      )

      deep_copy(dialog)
    end

    def SetFirewallInterfaceIntoZone(device, interface, zones)
      zones = deep_copy(zones)
      dialog = Frame(
        # TRANSLATORS: frame label
        _("Zone for Network Interface"),
        VBox(
          HBox(
            VBox(
              # FIXME: this label should show an interface name got as parameter
              Left(Label(device)),
              Left(Label(interface))
            ),
            ComboBox(
              Id("zone_for_interface"),
              Opt(:hstretch),
              # TRANSLATORS: select box
              _("&Interface Zone"),
              zones
            )
          ),
          VSpacing(1),
          ButtonBox(
            PushButton(
              Id("ok"),
              Opt(:okButton, :default, :key_F10),
              Label.OKButton
            ),
            PushButton(
              Id("cancel"),
              Opt(:cancelButton, :key_F9),
              Label.CancelButton
            )
          )
        )
      )

      deep_copy(dialog)
    end

    # Function returns dialog for additional zone strings (like 'any', 'auto'...)
    def AdditionalSettingsForZones(zones_additons)
      zones_additons = deep_copy(zones_additons)
      user_defined_zones = VBox()

      Builtins.foreach(zones_additons) do |zone_id, zone_attributes|
        user_defined_zones = Builtins.add(
          user_defined_zones,
          InputField(
            Id(Ops.add("zone_additions_", zone_id)),
            Opt(:hstretch),
            Ops.get(zone_attributes, "name", ""),
            Ops.get(zone_attributes, "items", "")
          )
        )
      end

      dialog = Frame(
        # TRANSLATORS: frame label
        _("Additional Interface Settings for Zones"),
        VBox(
          HStretch(),
          VSpacing(1),
          user_defined_zones,
          VSpacing(1),
          VSpacing(1),
          ButtonBox(
            PushButton(
              Id("ok"),
              Opt(:okButton, :default, :key_F10),
              Label.OKButton
            ),
            PushButton(
              Id("cancel"),
              Opt(:cancelButton, :key_F9),
              Label.CancelButton
            )
          )
        )
      )

      deep_copy(dialog)
    end

    def Masquerading
      dialog = Frame(
        # TRANSLATORS: frame label
        _("Masquerading"),
        VBox(
          ReplacePoint(Id("replacepoint_masquerade_information"), Empty()), #,
          #(IsThisExpertConfiguration() ?
          # TRANSLATORS: select box
          #    `Left( `ComboBox(`id("masquerade_outer_zone"), _("Zone &to Masquerade On"), GetZonesListedItems() ) )
          #    :
          #    nil
          #)
          Left(
            CheckBox(
              Id("masquerade_networks"),
              Opt(:notify),
              # TRANSLATORS: check box
              _("&Masquerade Networks")
            )
          )
        )
      )

      deep_copy(dialog)
    end

    def GetDefinedServicesListedItems
      services_list = []

      # sorted by service_name instead of service_id
      translations_to_service_ids = {}

      Builtins.foreach(SuSEFirewallServices.GetSupportedServices) do |service_id, service_name|
        # checking for yet defined name...
        if Ops.get(translations_to_service_ids, service_name) != nil
          Builtins.y2error(
            "More services with the same translation: %1",
            service_name
          )
        end
        Ops.set(translations_to_service_ids, service_name, service_id)
      end

      Builtins.foreach(translations_to_service_ids) do |service_name, service_id|
        services_list = Builtins.add(
          services_list,
          Item(Id(service_id), service_name)
        )
      end

      deep_copy(services_list)
    end

    def AllowedServices
      dialog = VBox(
        Left(
          ComboBox(
            Id("allowed_services_zone"),
            Opt(:notify),
            # TRANSLATORS: combo box
            _("All&owed Services for Selected Zone"),
            GetZonesListedItems()
          )
        ),
        VSpacing(1),
        HBox(
          VBox(
            Opt(:hstretch),
            Left(
              ReplacePoint(
                Id("allow_service_names_replacepoint"),
                # items handled by replacepoint
                # TRANSLATORS: combo box
                ComboBox(Id("allow_service_names"), _("&Service to Allow"), [])
              )
            ),
            Table(
              Id("table_allowed_services"),
              Opt(:hstretch, :vstretch, :keepSorting),
              Header(
                # TRANSLATORS: table header item
                _("Allowed Service"),
                # TRANSLATORS: table header item
                _("Description")
              ),
              []
            ),
            VSpacing(1),
            Left(
              CheckBox(
                Id("protect_from_internal"),
                Opt(:notify),
                # TRANSLATORS: check box
                _("&Protect Firewall from Internal Zone")
              )
            )
          ),
          HSquash(
            VBox(
              VSpacing(1.1),
              PushButton(
                Id("add_allowed_service"),
                Opt(:hstretch, :key_F3),
                Ops.add(Ops.add(" ", Label.AddButton), " ")
              ),
              PushButton(
                Id("remove_allowed_service"),
                Opt(:hstretch, :key_F5),
                Ops.add(Ops.add(" ", Label.DeleteButton), " ")
              ),
              Empty(Opt(:vstretch)),
              # TRANSLATORS: push button
              PushButton(
                Id("advanced_allowed_service"),
                Opt(:hstretch, :key_F7),
                " " + _("A&dvanced...") + " "
              )
            )
          )
        )
      )

      deep_copy(dialog)
    end

    def ExpertAcceptRules
      dialog = VBox(
        Left(
          ComboBox(
            Id("allowed_services_zone"),
            Opt(:notify),
            # TRANSLATORS: combo box
            _("Expert Rules Services for Selected Zone"),
            GetZonesListedItems()
          )
        ),
        VSpacing(1),
        VBox(
          Table(
            Id("table_expert_accept_rules"),
            Header(
              # TRANSLATORS: table header item
              _("Source Network"),
              # TRANSLATORS: table header item
              _("Protocol"),
              # TRANSLATORS: table header item
              _("Destination Port"),
              # TRANSLATORS: table header item
              _("Source Port")
            ),
            []
          ),
          HBox(
            PushButton(
              Id("add_redirect_to_masquerade"),
              Opt(:key_F3),
              Label.AddButton
            ),
            PushButton(
              Id("remove_redirect_to_masquerade"),
              Opt(:key_F5),
              Label.DeleteButton
            ),
            HStretch()
          )
        )
      )

      deep_copy(dialog)
    end

    def AdditionalServices(zone_name)
      dialog = HBox(
        # help text with a defined minimal size
        MinSize(30, 12, RichText(Id(:help_text), "")),
        HSpacing(1.5),
        Top(
          Frame(
            # TRANSLATORS: frame label
            _("Additional Allowed Ports"),
            VBox(
              HSpacing(45),
              VSpacing(1),
              # TRANSLATORS: label, %1 is a zone name like "External Zone"
              Left(
                Label(Builtins.sformat(_("Settings for Zone: %1"), zone_name))
              ),
              # TRANSLATORS: text entry
              InputField(Id("additional_tcp"), Opt(:hstretch), _("&TCP Ports")),
              # TRANSLATORS: text entry
              InputField(Id("additional_udp"), Opt(:hstretch), _("&UDP Ports")),
              # TRANSLATORS: text entry
              InputField(Id("additional_rpc"), Opt(:hstretch), _("&RPC Ports")),
              # TRANSLATORS: text entry
              InputField(
                Id("additional_ip"),
                Opt(:hstretch),
                _("&IP Protocols")
              ),
              VSpacing(1),
              ButtonBox(
                PushButton(
                  Id("ok"),
                  Opt(:okButton, :key_F10, :default),
                  Label.OKButton
                ),
                PushButton(
                  Id("cancel"),
                  Opt(:cancelButton, :key_F9),
                  Label.CancelButton
                )
              )
            )
          )
        )
      )

      deep_copy(dialog)
    end

    # Expert configuration only
    #
    #    term MasqueradeNetworks () {
    #	term dialog = `Frame (
    #	    // TRANSLATORS: frame label
    #	    _("Allowed Network Masquerading"),
    #	    `VBox (
    #		`Table (
    #		    `header (
    #			// TRANSLATORS: table header item
    #			_("Local Network"),
    #			// TRANSLATORS: table header item
    #			_("Destination Network"),
    #			// TRANSLATORS: table header item
    #			_("Protocol"),
    #			// TRANSLATORS: table header item
    #			_("Port")
    #		    ), []
    #		),
    #		`VSquash (
    #		    `HBox (
    #			`PushButton(`id("add_masquerade_network"), Label::AddButton()),
    #			`PushButton(`id("remove_masquerade_network"), Label::DeleteButton())
    #		    )
    #		)
    #	    )
    #	);
    #
    #	return dialog;
    #    }
    #

    #    term AddNetworkMasqueradeRule () {
    #	term dialog = `Frame (
    #	    // TRANSLATORS: frame label
    #	    _("Add New Allowed Masquerading Rule"),
    #	    `VBox (
    #		`HBox (
    #		    `HWeight ( 50,
    #		    `VBox (
    #			// TRANSLATORS: editable select box
    #			`ComboBox (`id("add_source_network"), `opt(`editable,`hstretch), _("&Source Network"), [
    #			    `item( `id("0/0"), "0/0")
    #			]),
    #			// TRANSLATORS: editable select box
    #			`ComboBox (`id("add_protocol"), `opt(`editable,`hstretch), _("&Protocol"), [
    #			    `item( `id(""), ""),
    #			    `item( `id("tcp"), "tcp"),
    #			    `item( `id("tcp"), "udp")
    #			])
    #		    )),
    #		    `HWeight ( 50,
    #		    `VBox (
    #			// TRANSLATORS: editable select box
    #			`ComboBox (`id("add_destination_network"), `opt(`editable,`hstretch), _("Destination Network"), [
    #			    `item( `id("0/0"), "0/0")
    #			]),
    #			// TRANSLATORS: text entry
    #			`InputField (`id("add_destination_port"), `opt (`hstretch), _("Port"))
    #		    ))
    #		),
    #		`VSpacing(1),
    #		`HBox (
    #		    `PushButton(`id("ok"), Label::AddButton()),
    #		    `PushButton(`id("cancel"), Label::CancelButton())
    #		)
    #	    )
    #	);
    #
    #	return dialog;
    #    }
    #

    def RedirectToMasqueradedIP
      dialog = Frame(
        # TRANSLATORS: frame label
        _("Redirect Requests to Masqueraded IP"),
        VBox(
          Table(
            Id("table_redirect_masq"),
            Header(
              # TRANSLATORS: table header item
              _("Source Network"),
              # TRANSLATORS: table header item
              _("Protocol"),
              # TRANSLATORS: table header item, Req. == Requested
              _("Req. IP"),
              # TRANSLATORS: table header item, Req. == Requested
              _("Req. Port"),
              "",
              # TRANSLATORS: table header item, Redir. == Redirect
              _("Redir. to IP"),
              # TRANSLATORS: table header item, Redir. == Redirect
              _("Redir. to Port")
            ),
            []
          ),
          HBox(
            PushButton(
              Id("add_redirect_to_masquerade"),
              Opt(:key_F3),
              Label.AddButton
            ),
            PushButton(
              Id("remove_redirect_to_masquerade"),
              Opt(:key_F5),
              Label.DeleteButton
            ),
            HStretch()
          )
        )
      )

      deep_copy(dialog)
    end

    def AddRedirectToMasqueradedIPRule
      dialog = Frame(
        # TRANSLATORS: frame label
        _("Add Masqueraded Redirect Rule"),
        VBox(
          VSpacing(1),
          # TRANSLATORS: section title in popup window
          Left(Label(_("Redirect Matching Rule:"))),
          HBox(
            VBox(
              # TRANSLATORS: editable select box
              ComboBox(
                Id("add_source_network"),
                Opt(:editable, :hstretch),
                _("&Source Network"),
                [Item(Id("0/0"), "0/0")]
              ),
              # TRANSLATORS: text entry
              InputField(
                Id("add_requested_ip"),
                Opt(:hstretch),
                _("Re&quested IP (Optional)")
              )
            ),
            HSpacing(1),
            VBox(
              # TRANSLATORS: select box
              ComboBox(
                Id("add_protocol"),
                Opt(:hstretch),
                _("&Protocol"),
                [Item(Id("tcp"), "TCP"), Item(Id("udp"), "UDP")]
              ),
              # TRANSLATORS: text entry
              InputField(
                Id("add_requested_port"),
                Opt(:hstretch),
                _("R&equested Port")
              )
            )
          ),
          VSpacing(1),
          # TRANSLATORS: section title in popup window
          Left(Label(_("Redirection:"))),
          HBox(
            # TRANSLATORS: text entry
            InputField(
              Id("add_redirectto_ip"),
              Opt(:hstretch),
              _("Re&direct to Masqueraded IP")
            ),
            HSpacing(1),
            # TRANSLATORS: text entry
            InputField(
              Id("add_redirectto_port"),
              Opt(:hstretch),
              _("&Redirect to Port (Optional)")
            )
          ),
          VSpacing(1),
          ButtonBox(
            PushButton(
              Id("ok"),
              Opt(:okButton, :default, :key_F10),
              Label.AddButton
            ),
            PushButton(
              Id("cancel"),
              Opt(:cancelButton, :key_F9),
              Label.CancelButton
            )
          )
        )
      )

      deep_copy(dialog)
    end

    # Only for Expert configuration
    #
    #    term TransparentLocalRedirection () {
    #	term dialog = `Frame (
    #	    _("Transparent Local Redirection"),
    #	    `VBox (
    #		`Left( `Label (_("Attention: Packets are transparently redirected to '127.0.0.1'."))),
    #		`Table (
    #		    `header (
    #			_("Source Network"),
    #			_("Destination Network"),
    #			_("Protocol"),
    #			_("Requested Port"),
    #			"",
    #			_("Local Port")
    #		    ),
    #		    // FIXME: fake items
    #		    [
    #			`item(`id("1"), "10.0.0.0/24", "0/0", "tcp", "http", UI::Glyph(`BulletArrowRight), "3128"),
    #			`item(`id("2"), "10.0.0.0/24", "0/0", "tcp", "smtp", UI::Glyph(`BulletArrowRight), "smtp"),
    #		    ]
    #		),
    #		`VSquash (
    #		    `HBox (
    #			`PushButton(`id("add_transparent_redirection"), Label::AddButton()),
    #			`PushButton(`id("remove_transparent_redirection"), Label::DeleteButton())
    #		    )
    #		)
    #	    )
    #	);
    #
    #	return dialog;
    #    }

    # Only for Expert configuration
    #
    #    term AddTransparentLocalRedirectionRule () {
    #	term dialog = `Frame (
    #	    _("Add New Transparent Local Redirection"),
    #	    `VBox (
    #		`VSpacing(1),
    #		`Left ( `Label(_("Transparent Redirection Matching Rule:")) ),
    #		`HBox (
    #		    `HWeight ( 10,
    #			`ComboBox (`id("add_source_network"), `opt(`editable,`hstretch), _("Source Network"), [
    #			    `item( `id("0/0"), "0/0")
    #			])
    #		    ),
    #		    `HWeight ( 10,
    #			`ComboBox (`id("add_destination_network"), `opt(`editable,`hstretch), _("Destination Network"), [
    #			    `item( `id("0/0"), "0/0")
    #			])
    #		    )
    #		),
    #		`HBox (
    #		    `HWeight ( 10,
    #			// FIXME: another protocols?
    #			`ComboBox (`id("add_protocol"), `opt(`hstretch), _("Protocol"), [
    #			    `item( `id("tcp"), "tcp"),
    #			    `item( `id("tcp"), "udp")
    #			])
    #		    ),
    #		    `HWeight ( 10,
    #			`InputField (`id("add_destination_port"), `opt (`hstretch), _("Requested Port"))
    #		    )
    #		),
    #		`VSpacing(1),
    #		`Left ( `Label(_("Transparently Redirect To:")) ),
    #		`InputField (`id("add_localredirect_port"), `opt (`hstretch), _("Local Port On 127.0.0.1")),
    #		`VSpacing(1),
    #		`HBox (
    #		    `PushButton(`id("ok"), Label::AddButton()),
    #		    `PushButton(`id("cancel"), Label::CancelButton())
    #		)
    #	    )
    #	);
    #
    #	return dialog;
    #    }

    # Only for Expert configuration
    #
    #    term ForwardNetworks () {
    #	term dialog = `Frame (
    #	    _("Forwarding Networks"),
    #	    `VBox (
    #		`Left( `Label(_("Atention: These networks are forwarder without any firewall filtering."))),
    #		`Table (
    #		    `header (
    #			_("Source Network"),
    #			_("Destination Network"),
    #			_("Protocol"),
    #			_("Port"),
    #			_("Flags")
    #		    ),
    #		    // FIXME: fake items
    #		    [
    #			`item(`id("1"), "0/0", "147.42.95.2", "tcp", "http", ""),
    #			`item(`id("1"), "0/0", "147.42.95.2", "tcp", "smtp", "")
    #		    ]
    #		),
    #		`VSquash (
    #		    `HBox (
    #			`PushButton(`id("add_forward_network"), Label::AddButton()),
    #			`PushButton(`id("remove_forward_network"), Label::DeleteButton())
    #		    )
    #		)
    #	    )
    #	);
    #
    #	return dialog;
    #    }

    # Only for Expert configuration
    #
    #    term AddForwardNetworkRule () {
    #	term dialog = `Frame (
    #	    _("Add New Forward Rule"),
    #	    `VBox (
    #		`VSpacing(1),
    #		`Left ( `Label(_("Allow Forwarding Matching This Rule:")) ),
    #		`HBox (
    #		    `HWeight ( 10,
    #			`ComboBox (`id("add_source_network"), `opt(`editable,`hstretch), _("Source Network"), [
    #			    `item( `id("0/0"), "0/0")
    #			])
    #		    ),
    #		    `HWeight ( 10,
    #			`ComboBox (`id("add_destination_network"), `opt(`editable,`hstretch), _("Destination Network"), [
    #			    `item( `id("0/0"), "0/0")
    #			])
    #		    )
    #		),
    #		`HBox (
    #		    `HWeight ( 10,
    #			// FIXME: another protocols?
    #			`ComboBox (`id("add_protocol"), `opt(`hstretch), _("Protocol"), [
    #			    `item( `id("tcp"), "tcp"),
    #			    `item( `id("tcp"), "udp"),
    #			    `item( `id("icmp"), "icmp"),
    #			    `item( `id("icmp"), "esp (IPsec)"),
    #			    `item( `id(""), ""),
    #			])
    #		    ),
    #		    `HWeight ( 10,
    #			`InputField (`id("add_port"), `opt (`hstretch), _("Port"))
    #		    )
    #		),
    #		`VSpacing(1),
    #		`HBox (
    #		    `PushButton(`id("ok"), Label::AddButton()),
    #		    `PushButton(`id("cancel"), Label::CancelButton())
    #		)
    #	    )
    #	);
    #
    #	return dialog;
    #    }

    # Only for Expert configuration
    #
    #    term RoutingInZones () {
    #	term dialog = `Frame (
    #	    _("Routing In Zones"),
    #	    `Left (
    #		// Allow Same-Class Routing
    #		`CheckBox (`id("same_class_routing"),
    #		    _("Allow Routing Between Interfaces in The Same Zone")
    #		)
    #	    )
    #	);
    #
    #	return dialog;
    #    }

    # Only for Expert configuration
    #
    #    term LoggingTuning () {
    #	term dialog = `Frame (
    #	    _("Logging Tuning"),
    #	    `VBox (
    #		`Left (
    #		    `HBox (
    #			// FIXME: fake frequency
    #			`HVSquash ( `InputField (`id("frequency"), `opt (`hstretch), _("Frequency"), "3")),
    #			`VBox ( `Label(""), `Label ("/") ),
    #			`ComboBox (`id("unit"),	 _("Unit"), [
    #			    `item(`id("second"), _("Second")),
    #			    `item(`id("minute"), _("Minute")),
    #			    `item(`id("hour"),   _("Hour")),
    #			    `item(`id("day"),    _("Day"))
    #			])
    #		    )
    #		),
    #		`Left (
    #		    `HBox (
    #			// FIXME: fake log file
    #			`InputField (`id("file_name"), `opt (`hstretch), Label::FileName(), "/var/log/SuSEfirewall2"),
    #			`VBox ( `Label(""), `PushButton (`id("browse_logfile"), Label::BrowseButton()) )
    #		    )
    #		)
    #	    )
    #	);
    #
    #	return dialog;
    #    }

    def LoggingLevel
      logging_options = [
        # TRANSLATORS: select box item
        Item(Id("ALL"), _("Log All")),
        # TRANSLATORS: select box item
        Item(Id("CRIT"), _("Log Only Critical")),
        # TRANSLATORS: select box item
        Item(Id("NONE"), _("Do Not Log Any"))
      ]

      dialog = VBox(
        Frame(
          _("Logging Level"),
          VBox(
            Left(
              # TRANSLATORS: select box
              ComboBox(
                Id("logging_ACCEPT"),
                _("&Logging Accepted Packets"),
                logging_options
              )
            ),
            Left(
              # TRANSLATORS: select box
              ComboBox(
                Id("logging_DROP"),
                _("L&ogging Not Accepted Packets"),
                logging_options
              )
            )
          )
        )
      )

      deep_copy(dialog)
    end

    # Only for Expert configuration
    #
    #    term BroadcastConfigurationExpert () {
    #	term dialog = `Frame (
    #	    _("Broadcast Configuration"),
    #	    `VBox (
    #		`RadioButtonGroup (`id("broadcast_configuration"),
    #		    `VBox (
    #			`Left ( `RadioButton (`id("drop_incoming"), _("Drop Incoming Broadcast")) ),
    #			`Left( `RadioButton (`id("allow_incoming"), _("Allow Incoming Broadcast")) )
    #		    )
    #		),
    #		`HBox (
    #		    `HWeight( 4,
    #			`Empty()
    #		    ),
    #		    `HWeight( 50,
    #			`MultiSelectionBox (`id("accept_broadcast_packets"),
    #			    _("Firewall Zones Allowing Broadcast Packets"),
    #			    GetZonesListedItems()
    #			)
    #		    )
    #		),
    #		`Left (
    #		    `CheckBox (`id("dropped_packets"), _("Log Not Accepted Broadcast Packets"))
    #		)
    #	    )
    #	);
    #
    #	return dialog;
    #    }

    def BroadcastConfigurationSimple
      dialog = Frame(
        _("Broadcast Configuration"),
        ReplacePoint(Id("replace_point_bcast"), Empty())
      )

      deep_copy(dialog)
    end

    def BroadcastReply
      dialog = VBox(
        Left(Label(_("Accepting the Broadcast Reply"))),
        Table(
          Id("table_broadcastreply"),
          Header(_("Zone"), _("Service"), _("Accepted from Network")),
          []
        ),
        Left(
          HBox(
            PushButton(Id(:add_br), Opt(:key_F3), _("&Add...")),
            PushButton(Id(:delete_br), Opt(:key_F5), _("&Delete"))
          )
        )
      )

      deep_copy(dialog)
    end

    # Only for Expert configuration
    #
    #    term HierarchicalTokenBucket () {
    #	term dialog = `Frame (
    #	    _("Hierarchical Token Bucket"),
    #	    `VBox (
    #		`Left ( `Label (_("Adjust upstream limit for selected interface")) ),
    #		`HBox (
    #		    `HWeight ( 3,
    #			`ComboBox (`id("htb_interface"), _("Interface"), [
    #			    // FIXME: fake items
    #			    `item(`id(1), "RTL-8139 / eth-aa-bb-cc-dd-ee"),
    #			    `item(`id(1), "Askey 815C / modem0")
    #			])
    #		    ),
    #		    `HWeight ( 1,
    #			`InputField (`id("htb_unit"), `opt(`hsquash), _("kbit/sec."))
    #		    )
    #		)
    #	    )
    #	);
    #
    #	return dialog;
    #    }

    # Only for Expert configuration
    #
    #    term AdvancedSecuritySettings () {
    #	term dialog = `Frame (
    #	    _("Advanced Security Settings"),
    #	    `VBox (
    #		`Left( `ComboBox (`id("disallowed_packets"), _("Disallowed Packets"), [
    #		    `item(`id("drop"), _("Drop")),
    #		    `item(`id("drop"), _("Reject"))
    #		])),
    #		`Left ( `CheckBox (`id("block_new_connections"), _("Block New Connections from This Host")) ),
    #		`Left ( `CheckBox (`id("allow_ping"), _("Allow to Ping This Host")) ),
    #		`Left ( `CheckBox (`id("allow_traceroute"), _("Allow Traceroute through This Host")) )
    #	    )
    #	);
    #
    #	return dialog;
    #    }

    def IPsecSupport
      dialog = Frame(
        _("IPsec Support"),
        HBox(
          # TRANSLATORS: check box
          Left(CheckBox(Id("ispsec_support"), _("&Enabled"))),
          HStretch(),
          # TRANSLATORS: push button
          Right(PushButton(Id("ipsec_details"), _("&Details...")))
        )
      )

      deep_copy(dialog)
    end

    def IPsecTrustAsZone
      trust_zones = Builtins.add(
        GetZonesListedItems(),
        Item(
          Id("no"),
          # TRANSLATORS: select box item, trust IPsec packet the same as the origin of the packet
          _("Same Zone as Original Source Network")
        )
      )

      dialog = Frame(
        # TRANSLATORS: frame label
        _("IPsec Zone"),
        VBox(
          VSpacing(1),
          Left(
            ComboBox(
              Id("trust_ipsec_as"),
              # TRANSLATORS: select box
              _("&Trust IPsec As"),
              trust_zones
            )
          ),
          VSpacing(1),
          ButtonBox(
            PushButton(
              Id("ok"),
              Opt(:okButton, :default, :key_F10),
              Label.OKButton
            ),
            PushButton(
              Id("cancel"),
              Opt(:cancelButton, :key_F9),
              Label.CancelButton
            )
          )
        )
      )

      deep_copy(dialog)
    end

    # Only for Expert configuration
    #
    #    term IPv6Support () {
    #	term dialog = `Frame (
    #	    _("IPv6 Support"),
    #	    `VBox (
    #		`Label ("H I C   S U N T   L E O N E S")
    #	    )
    #	);
    #
    #	return dialog;
    #    }

    def CustomFirewallRules
      dialog = Frame(
        _("Custom Allowed Rules"),
        VBox(
          Left(
            ComboBox(
              Id("custom_rules_firewall_zone"),
              Opt(:notify),
              # TRANSLATORS: combo box
              _("Firewall &Zone"),
              GetZonesListedItems()
            )
          ),
          VSpacing(1),
          Table(
            Id("custom_rules_table"),
            Header(
              _("Source Network"),
              _("Protocol"),
              _("Destination Port"),
              _("Source Port"),
              _("Options")
            ),
            []
          ),
          HBox(
            PushButton(Id("add_custom_rule"), Opt(:key_F3), Label.AddButton),
            PushButton(
              Id("remove_custom_rule"),
              Opt(:key_F5),
              Label.DeleteButton
            ),
            HStretch()
          )
        )
      )

      deep_copy(dialog)
    end

    def AddCustomFirewallRule
      VBox(
        Frame(
          _("Add New Allowing Rule"),
          VBox(
            InputField(
              Id("add_source_network"),
              Opt(:hstretch),
              _("Source &Network")
            ),
            Left(
              ComboBox(
                Id("add_protocol"),
                _("&Protocol"),
                [
                  Item(Id("tcp"), SuSEFirewall.GetProtocolTranslatedName("tcp")),
                  Item(Id("udp"), SuSEFirewall.GetProtocolTranslatedName("udp")),
                  Item(
                    Id("_rpc_"),
                    SuSEFirewall.GetProtocolTranslatedName("_rpc_")
                  )
                ]
              )
            ),
            InputField(
              Id("add_destination_port"),
              Opt(:hstretch),
              _("&Destination Port (Optional)")
            ),
            InputField(
              Id("add_source_port"),
              Opt(:hstretch),
              _("&Source Port (Optional)")
            ),
            InputField(
              Id("add_options"),
              Opt(:hstretch),
              _("Additional &Options (Optional)")
            )
          )
        ),
        VSpacing(1),
        ButtonBox(
          PushButton(
            Id("ok"),
            Opt(:okButton, :default, :key_F10),
            Label.AddButton
          ),
          PushButton(
            Id("cancel"),
            Opt(:cancelButton, :key_F9),
            Label.CancelButton
          )
        )
      )
    end

    # local helper function for Summary
    def HTMLWrong(emphasize_string)
      Builtins.sformat("<font color='#993300'>%1</font>", emphasize_string)
    end

    def BoxSummary
      dialog = VBox(
        # TRANSLATORS: informative label in dialog
        RichText(Id("box_summary_richtext"), _("Creating summary...")),
        VSpacing(1),
        # TRANSLATORS: check box in summary dialog
        Left(CheckBox(Id("show_details"), Opt(:notify), _("&Show Details")))
      )

      deep_copy(dialog)
    end
  end
end
