

## Open / Modify Firewall Services

A [firewalld service](http://www.firewalld.org/documentation/man-pages/firewalld.service.html) defines a set of ports, protocols and destination addresses simplyfying the process of allow/open them in a specific zone.

In `YaST`, the [CWMFirewallInterfaces](https://github.com/yast/yast-yast2/tree/master/library/network/src/modules/CWMFirewallInterfaces.rb) module provides a widget definition for manipulating the enablement of services in zones through a selection of interfaces (each interface belongs to a **ZONE**). The module has been adapted to work properly with the new `firewalld API`.

![summaryofchannges](https://user-images.githubusercontent.com/7056681/35337660-b5700d4c-0113-11e8-829f-0d92cdfe97e3.png)

Being the implementation something like:

```ruby

Yast.import "CWMFirewallInterfaces"

# You can still use "service:" prepend although it is recommended to remove
# it when adapting the module
settings = { "services" => ["service:cluster"], "display_details" => true }
CWMFirewallInterfaces.CreateOpenFirewallWidget(settings)
```

In most cases the only requirement will be to define the service in `firewalld` and probably it will be already
provided by the `firewalld` package. In summary the changes in code should look like:

```ruby

# Require the new firewalld library and drop any import of SuSEFirewall2
require 'y2firewall/firewalld'

  ## This is not required but it is more elegant than using the complete call every time
  def firewalld
    Y2Firewall::Firewalld.instance
  end

  # In your Module.Read method replace SuSEFirewalld.Read by firewalld.read
    firewalld.read
  # # In your Module.Write method replace SuSEFirewalld.Write by firewalld.read
    firewalld.write
  

```

### Modify Service Ports Definition

The service definitions shipped with firewalld can be modified. By default all the service definitions that came with firewalld are placed in `/usr/lib/firewalld/services` although if a service is modified then it is placed in `/etc/firewalld/services` allowing the admin to go back to the original definition if needed.

SuSEFirewallServices has been dropped, so services configuration should be done through the new `Y2Firewall::Firewalld::Service` class.

To modify the ports associated with a specific service, the class method `modify_ports` has been provided making the call as similar to the old one (`SetNeededPortsAndProtocols`) as possible.

```ruby
      
      # SuSEFirewallServices.SetNeededPortsAndProtocols("service:cluster", { "tcp_ports" => tcp_ports })
      begin
        Y2Firewall::Firewalld::Service.modify_ports(name: "cluster", tcp_ports: tcp_ports)
      rescue Y2Firewall::Firewalld::Service::NotFound
        y2error("Firewalld 'cluster' service is not available.")
      end
```

To get the list of service ports we have to ask the service object itself.

```ruby
      # SuSEFirewallServices.GetNeededTCPPorts("service:cluster")
      begin
        fwd_cluster = firewalld.find_service("cluster")
        tcp_ports = fwd_cluster.tcp_ports
      rescue Y2Firewall::Firewalld::Service::NotFound
        tcp_ports = []
      end

```

## Important Note:

If a `firewalld service` is not defined, then the `CWMFirewallInterfaces` widget will show a list of missing services suggesting to deploy them to be able to configure the firewall.

![notfoundservice](https://user-images.githubusercontent.com/7056681/35266550-87617114-001b-11e8-9135-512925964891.png)

New `services` can be created through the **API** or by a custom `XML` file although the preferred way is to define them in the `RPM` specification**. Please refer to this [link](https://en.opensuse.org/Firewalld/RPM_Packaging) for further information.

Find a complete example including all the needed changes in this yast2-cluster [PR]((https://github.com/yast/yast-cluster/pull/34))
