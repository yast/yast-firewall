require "yast"

module Y2Firewall
  class ProposalSettings
    include Yast::Logger
    include Yast::I18n
    attr_accessor :enable_firewall, :enable_sshd, :open_ssh, :open_vnc

    def initialize
      Yast.import "PackagesProposal"
      Yast.import "ProductFeatures"
      Yast.import "Linuxrc"

      load_features
      enable_firewall! if @enable_firewall
      enable_sshd! if Yast::Linuxrc.usessh || @enable_sshd
      open_ssh! if Yast::Linuxrc.usessh || @open_ssh
      open_vnc! if Yast::Linuxrc.vnc
    end

    def load_features
      load_feature(:enable_firewall, :enable_firewall)
      load_feature(:firewall_enable_ssh, :open_ssh)
      load_feature(:enable_sshd, :enable_sshd)
    end

    # Services

    def enable_firewall!
      Yast::PackagesProposal.AddResolvables("firewall", :package, ["firewalld"])

      log.info "Enabling Firewall"
      self.enable_firewall = true
    end

    def disable_firewall!
      Yast::PackagesProposal.RemoveResolvables("firewall", :package, ["firewalld"])
      log.info "Disabling Firewall"
      self.enable_firewall = false
    end

    def enable_sshd!
      Yast::PackagesProposal.AddResolvables("firewall", :package, ["openssh"])
      log.info "Enabling SSHD"
      self.enable_sshd = true
    end

    def disable_sshd!
      Yast::PackagesProposal.RemoveResolvables("firewall", :package, ["openssh"])
      log.info "Disabling SSHD"
      self.enable_sshd = false
    end

    def open_ssh!
      log.info "Opening SSH port"
      self.open_ssh = true
    end

    def close_ssh!
      log.info "Opening SSH port"
      self.open_ssh = false
    end

    def open_vnc!
      log.info "Close VNC port"
      self.open_vnc = true
    end

    def close_vnc!
      log.info "Close VNC port"
      self.open_vnc = false
    end

  private

    def load_feature(feature, to, source: global_section)
      value = Yast::Ops.get(source, feature.to_s)
      send("#{to}=", value) unless value.nil?
    end

    def global_section
      Yast::ProductFeatures.GetSection("globals")
    end

    class << self
      def run
        instance.run
      end

      # Singleton instance
      def instance
        create_instance unless @instance
        @instance
      end

      # Enforce a new clean instance
      def create_instance
        @instance = new
      end

      # Make sure only .instance and .create_instance can be used to
      # create objects
      private :new, :allocate
    end
  end
end
