#!/usr/bin/env rspec

require_relative "../test_helper"
load File.expand_path("../../../src/clients/firewall_auto.rb", __FILE__)

Yast.import "SuSEFirewall"

describe Yast::FirewallAutoClient do
  describe "#main" do
    before do
      allow(Yast::WFM).to receive(:Args) do |n|
        n.nil? ? args : args[n]
      end
    end

    describe "summary action" do
      let(:args) { ["Summary"] }

      it "shows firewall zones" do
        allow(Yast::SuSEFirewall).to receive(:GetKnownFirewallZones)
          .and_return([])
        expect(subject).to receive(:InitBoxSummary).with([])
          .and_return("Some summary")
        expect(subject.main).to eq("Some summary")
      end
    end

    describe "Reset" do
      let(:args) { ["Reset"] }

      it "empties the firewall configuration and disables it" do
        expect(Yast::SuSEFirewall).to receive(:Import).with({})
        expect(Yast::SuSEFirewall).to receive(:SetEnableService).with(false)
        expect(subject.main).to eq({})
      end
    end

    describe "Packages" do
      let(:args) { ["Packages"] }

      it "returns SuSEfirewall2 package" do
        expect(subject.main).to eq("install" => ["SuSEfirewall2"])
      end
    end

    describe "Change" do
      let(:args) { ["Change"] }

      it "runs wizard, set 'start' value and returns wizard's result" do
        expect(subject).to receive(:FirewallAutoSequence).and_return(:some_value)
        expect(Yast::SuSEFirewall).to receive(:GetEnableService).and_return(false)
        expect(Yast::SuSEFirewall).to receive(:SetStartService).with(false)
        expect(subject.main).to eq(:some_value)
      end
    end

    describe "Import" do
      let(:args) { ["Import", config] }
      let(:config) { { "start_firewall" => true } }

      it "imports configuration and returns nil" do
        expect(Yast::SuSEFirewall).to receive(:Import).with(config).and_return(nil)
        expect(subject.main).to be_nil
      end
    end

    describe "Read" do
      let(:args) { ["Read"] }

      it "reads firewall configuration and returns operation's result" do
        expect(Yast::SuSEFirewall).to receive(:Read).and_return(:some_result)
        expect(subject.main).to eq(:some_result)
      end
    end

    describe "Export" do
      let(:args) { ["Export"] }
      let(:config) { { "start_firewall" => true } }

      it "returns firewall configuration" do
        expect(Yast::SuSEFirewall).to receive(:Export).and_return(config)
        expect(subject.main).to eq(config)
      end
    end

    describe "GetModified" do
      let(:args) { ["GetModified"] }

      it "checks whether the configuration was modified or not" do
        expect(Yast::SuSEFirewall).to receive(:GetModified).and_return(true)
        expect(subject.main).to eq(true)
      end
    end

    describe "SetModified" do
      let(:args) { ["SetModified"] }

      it "marks configuration as modified and returns true" do
        expect(Yast::SuSEFirewall).to receive(:SetModified)
        expect(subject.main).to eq(true)
      end
    end

    describe "Write" do
      let(:args) { ["Write"] }

      it "writes firewall configuration and returns operation's result" do
        expect(Yast::SuSEFirewall).to receive(:Write).and_return(:some_result)
        expect(subject.main).to eq(:some_result)
      end
    end
  end
end
