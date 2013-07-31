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
# File:	firewall/wizards.ycp
# Package:	Firewall configuration
# Summary:	Wizards definition
# Authors:	Lukas Ocilka <locilka@suse.cz>
#
# $Id$
module Yast
  module FirewallDialogsInclude
    def initialize_firewall_dialogs(include_target)
      textdomain "firewall"

      Yast.import "CWM"
      Yast.import "CWMServiceStart"
      Yast.import "DialogTree"
      Yast.import "Label"
      Yast.import "Mode"
      Yast.import "SuSEFirewall"
      Yast.import "Wizard"

      Yast.include include_target, "firewall/subdialogs.rb"
      Yast.include include_target, "firewall/uifunctions.rb"
      Yast.include include_target, "firewall/helps.rb"
      Yast.include include_target, "firewall/summary.rb"

      @widgets_handling = {
        "auto_start_up"                     => CWMServiceStart.CreateAutoStartWidget(
          {
            "get_service_auto_start" => fun_ref(
              SuSEFirewall.method(:GetEnableService),
              "boolean ()"
            ),
            # Special function that adjusts the firewall
            #    enabled + start (after Write())
            #    or
            #    disabled + stop (after Write())
            "set_service_auto_start" => fun_ref(
              method(:SetEnableFirewall),
              "void (boolean)"
            ),
            # TRANSLATORS: Radio selection, See #h1
            "start_auto_button"      => _(
              "&Enable Firewall Automatic Starting"
            ),
            # TRANSLATORS: Radio selection, See #h2
            "start_manual_button"    => _(
              "&Disable Firewall Automatic Starting"
            ),
            "help"                   => Builtins.sformat(
              CWMServiceStart.AutoStartHelpTemplate,
              # TRANSLATORS: part of help text describind #h1, Do not use any shortcut
              _("Enable Firewall Automatic Starting"),
              # TRANSLATORS: part of help text describing #h2, Do not use any shortcut
              _("Disable Firewall Automatic Starting")
            )
          }
        ),
        "start_stop"                        => CWMServiceStart.CreateStartStopWidget(
          {
            "service_id"                => "SuSEfirewall2",
            # TRANSLATORS: status information
            "service_running_label"     => _(
              "Firewall is running"
            ),
            # TRANSLATORS: status information
            "service_not_running_label" => _(
              "Firewall is not running"
            ),
            # TRANSLATORS: Push button
            "start_now_button"          => _(
              "&Start Firewall Now"
            ),
            # TRANSLATORS: Push button
            "stop_now_button"           => _(
              "S&top Firewall Now"
            ),
            "save_now_action"           => fun_ref(
              method(:SaveAndRestart),
              "boolean ()"
            ),
            # TRANSLATORS: Push button
            "save_now_button"           => _(
              "Sa&ve Settings and Restart Firewall Now"
            ),
            "start_now_action"          => fun_ref(
              method(:StartNow),
              "boolean ()"
            ),
            "stop_now_action"           => fun_ref(
              method(:StopNow),
              "boolean ()"
            ),
            "help"                      => Builtins.sformat(
              CWMServiceStart.StartStopHelpTemplate(true),
              # TRANSLATORS: part of help text - push button label, NO SHORTCUT!!!
              _("Start Firewall Now"),
              # TRANSLATORS: part of help text - push button label, NO SHORTCUT!!!
              _("Stop Firewall Now"),
              # TRANSLATORS: part of help text - push button label, NO SHORTCUT!!!
              _("Save Settings and Restart Firewall Now")
            )
          }
        ),
        # hack function for disabling BackButton
        "DisableBackButton"                 => {
          "widget"        => :custom,
          "custom_widget" => Empty(),
          "init"          => fun_ref(
            method(:DisableBackButton),
            "void (string)"
          ),
          "help"          => " "
        },
        "FirewallInterfaces"                => {
          "widget"        => :custom,
          "custom_widget" => VBox(),
          "init"          => fun_ref(
            method(:InitFirewallInterfaces),
            "void (string)"
          ),
          "handle"        => fun_ref(
            method(:HandleFirewallInterfaces),
            "symbol (string, map)"
          ),
          #"store"		: NoStoreNeeded,
          "help"          => HelpForDialog(
            "firewall-interfaces"
          )
        },
        "AllowedServices"                   => {
          "widget"        => :custom,
          "custom_widget" => VBox(),
          "init"          => fun_ref(
            method(:InitAllowedServices),
            "void (string)"
          ),
          "handle"        => fun_ref(
            method(:HandleAllowedServices),
            "symbol (string, map)"
          ),
          #"store"		: NoStoreNeeded,
          "help"          => HelpForDialog(
            "allowed-services"
          )
        },
        "Masquerading"                      => {
          "widget"        => :custom,
          "custom_widget" => VBox(),
          "init"          => fun_ref(method(:InitMasquerading), "void (string)"),
          "handle"        => fun_ref(
            method(:HandleMasquerading),
            "symbol (string, map)"
          ),
          #"store"		: NoStoreNeeded,
          "help"          => HelpForDialog(
            "base-masquerading"
          )
        },
        "BroadcastConfigurationSimple"      => {
          "widget"        => :custom,
          "custom_widget" => VBox(),
          "init"          => fun_ref(
            method(:InitBroadcastConfigurationSimple),
            "void (string)"
          ),
          #"handle"		: NoHandlingNeeded,
          "store"         => fun_ref(
            method(:StoreBroadcastConfigurationSimple),
            "void (string, map)"
          ),
          "help"          => HelpForDialog("simple-broadcast-configuration")
        },
        "BroadcastReply"                    => {
          "widget"        => :custom,
          "custom_widget" => VBox(),
          "init"          => fun_ref(
            method(:InitBroadcastReply),
            "void (string)"
          ),
          "handle"        => fun_ref(
            method(:HandleBroadcastReply),
            "symbol (string, map)"
          ),
          "help"          => HelpForDialog("broadcast-reply")
        },
        # 	IPsec is not supported any more (no service defined by package)
        #
        # 	"IPsecSupport"		: $[
        # 	    "widget"		: `custom,
        # 	    "custom_widget"	: `VBox(),
        # 	    "init"		: InitIPsecSupport,
        # 	    "handle"		: HandleIPsecSupport,
        # 	    "store"		: StoreIPsecSupport,
        # 	    "help"		: HelpForDialog("base-ipsec-support"),
        # 	],
        "LoggingLevel"                      => {
          "widget"        => :custom,
          "custom_widget" => VBox(),
          "init"          => fun_ref(method(:InitLoggingLevel), "void (string)"),
          #"handle"		: NoHandlingNeeded,
          "store"         => fun_ref(
            method(:StoreLoggingLevel),
            "void (string, map)"
          ),
          "help"          => HelpForDialog("base-logging")
        },
        "RedirectToMasqueradedIP"           => {
          "widget"        => :custom,
          "custom_widget" => VBox(),
          "init"          => fun_ref(
            method(:InitRedirectToMasqueradedIP),
            "void (string)"
          ),
          "handle"        => fun_ref(
            method(:HandleRedirectToMasqueradedIP),
            "symbol (string, map)"
          ),
          #"store"		: NoStoreNeeded,
          "help"          => HelpForDialog(
            "masquerade-redirect-table"
          )
        },
        "CustomRules"                       => {
          "widget"        => :custom,
          "custom_widget" => VBox(),
          "init"          => fun_ref(method(:InitCustomRules), "void (string)"),
          "handle"        => fun_ref(
            method(:HandleCustomRules),
            "symbol (string, map)"
          ),
          # "store"		: NoStoreNeeded,
          "help"          => HelpForDialog(
            "custom-rules"
          )
        },
        "CheckServiceStartVsStartedStopped" => {
          "widget"        => :custom,
          "custom_widget" => Empty(),
          "init"          => fun_ref(
            method(:InitServiceStartVsStartedStopped),
            "void (string)"
          ),
          "help"          => " "
        }
      }

      # TRANSLATORS: Part of dialog caption
      @firewall_caption = _("Firewall Configuration")

      @tabs = {
        "start_up"         => {
          "contents"        => VBox(
            "auto_start_up",
            VSpacing(1),
            # disabling start/stop buttons when it doesn't make sense
            Mode.normal ? "start_stop" : Empty(),
            Mode.normal ? "CheckServiceStartVsStartedStopped" : Empty(),
            VStretch()
          ),
          # TRANSLATORS: part of dialog caption
          "caption"         => Ops.add(
            Ops.add(@firewall_caption, ": "),
            _("Start-Up")
          ),
          # TRANSLATORS: tree menu item
          "tree_item_label" => _("Start-Up"),
          "widget_names"    => [
            "DisableBackButton",
            "auto_start_up",
            "start_stop",
            "CheckServiceStartVsStartedStopped"
          ]
        },
        "interfaces"       => {
          "contents"        => VBox(FirewallInterfaces(), VSpacing(1)),
          # TRANSLATORS: part of dialog caption
          "caption"         => Ops.add(
            Ops.add(@firewall_caption, ": "),
            _("Interfaces")
          ),
          # TRANSLATORS: tree menu item
          "tree_item_label" => _("Interfaces"),
          "widget_names"    => ["DisableBackButton", "FirewallInterfaces"]
        },
        "allowed_services" => {
          "contents"        => VBox(AllowedServices(), VSpacing(1)),
          # TRANSLATORS: part of dialog caption
          "caption"         => Ops.add(
            Ops.add(@firewall_caption, ": "),
            _("Allowed Services")
          ),
          # TRANSLATORS: tree menu item
          "tree_item_label" => _(
            "Allowed Services"
          ),
          "widget_names"    => ["DisableBackButton", "AllowedServices"]
        },
        "masquerading"     => {
          "contents"        => VBox(
            Masquerading(),
            VSpacing(1),
            RedirectToMasqueradedIP(),
            VSpacing(1)
          ),
          # TRANSLATORS: part of dialog caption
          "caption"         => Ops.add(
            Ops.add(@firewall_caption, ": "),
            _("Network Masquerading")
          ),
          # TRANSLATORS: tree menu item
          "tree_item_label" => _("Masquerading"),
          "widget_names"    => [
            "DisableBackButton",
            "Masquerading",
            "RedirectToMasqueradedIP"
          ]
        },
        "broadcast_simple" => {
          "contents"        => VBox(
            BroadcastConfigurationSimple(),
            VSpacing(1),
            BroadcastReply(),
            VStretch()
          ),
          # TRANSLATORS: part of dialog caption
          "caption"         => Ops.add(
            Ops.add(@firewall_caption, ": "),
            _("Broadcast")
          ),
          # TRANSLATORS: tree menu item
          "tree_item_label" => _("Broadcast"),
          "widget_names"    => [
            "DisableBackButton",
            "BroadcastConfigurationSimple",
            "BroadcastReply"
          ]
        },
        # 	IPsec is not supported any more (no service defined by package)
        #
        # 	"ipsec_support"		: $[
        # 	    "contents"		: `VBox (
        # 		IPsecSupport(),
        # 		`VStretch ()
        # 	    ),
        # 	    // TRANSLATORS: part of dialog caption
        # 	    "caption"		: firewall_caption + ": " + _("IPsec Support"),
        # 	    // TRANSLATORS: tree menu item
        # 	    "tree_item_label"	: _("IPsec Support"),
        # 	    "widget_names"	: [ "DisableBackButton", "IPsecSupport" ]
        # 	],
        "logging_level"    => {
          "contents"        => VBox(LoggingLevel(), VStretch()),
          # TRANSLATORS: part of dialog caption
          "caption"         => Ops.add(
            Ops.add(@firewall_caption, ": "),
            _("Logging Level")
          ),
          # TRANSLATORS: tree menu item
          "tree_item_label" => _("Logging Level"),
          "widget_names"    => ["DisableBackButton", "LoggingLevel"]
        },
        "custom_rules"     => {
          "contents"        => VBox(CustomFirewallRules()),
          # TRANSLATORS: part of dialog caption
          "caption"         => Ops.add(
            Ops.add(@firewall_caption, ": "),
            _("Custom Rules")
          ),
          # TRANSLATORS: tree menu item
          "tree_item_label" => _("Custom Rules"),
          "widget_names"    => ["DisableBackButton", "CustomRules"]
        }
      }

      @functions = { :abort => fun_ref(method(:AbortDialog), "boolean ()") }
    end

    def RunFirewallDialogs
      simple_dialogs = [
        "start_up",
        "interfaces",
        "allowed_services",
        "masquerading",
        "broadcast_simple", # "ipsec_support",
        "logging_level",
        "custom_rules"
      ]

      DialogTree.ShowAndRun(
        {
          "ids_order"      => simple_dialogs,
          "initial_screen" => "start_up",
          "screens"        => @tabs,
          "widget_descr"   => @widgets_handling,
          "back_button"    => Label.BackButton,
          "abort_button"   => Label.CancelButton,
          # if 'normal' or 'installation', [Next] button, else [OK]
          "next_button"    => Mode.normal(
          ) ?
            Label.NextButton :
            Label.OKButton,
          "functions"      => @functions
        }
      )
    end

    def BoxSummaryDialog
      Wizard.SetContentsButtons(
        Ops.add(
          Ops.add(
            # TRANSLATORS: part of dialog caption
            @firewall_caption,
            ": "
          ),
          _("Summary")
        ),
        BoxSummary(),
        HelpForDialog("box-summary"),
        Label.BackButton,
        Mode.normal ? Label.FinishButton : Label.OKButton
      )
      Wizard.SetAbortButton(:abort, Label.CancelButton)
      SetFirewallIcon()
      UI.ChangeWidget(Id(:back), :Enabled, true)

      InitBoxSummary([])

      ret = nil
      while true
        ret = UI.UserInput

        break if ret == :back || ret == :next

        # bugzilla #249777, `cancel == [x] (Closing YaST UI).
        if (ret == :abort || ret == :cancel) && AbortDialog() == true
          # ret is evaluated by the dialog sequencer
          ret = :abort
          break
        end

        if ret == "show_details"
          SuSEFirewallUI.SetShowSummaryDetails(
            Convert.to_boolean(UI.QueryWidget(Id("show_details"), :Value))
          )
          InitBoxSummary([])
        end
      end

      Convert.to_symbol(ret)
    end
  end
end
