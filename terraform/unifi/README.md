# unifi

Settings of the UniFi Cloud Gateway Ultra that the cluster depends on, as far as they are managed here. Everything else
stays in the UI.

| File                 | Holds                                                                                     |
| -------------------- | ----------------------------------------------------------------------------------------- |
| `network.tf`         | The networks: the LAN, the Servers VLAN of the nodes, IPTV, IoT and Guest                 |
| `port_forwards.tf`   | The port forwards to the public Envoy Gateway and Plex                                    |
| `wlan.tf`            | The Wi-Fi networks, without their passphrases, which are set in the UI                    |
| `bgp.tf`, `bgp.conf` | The gateway's side of the BGP sessions with Cilium, as FRR config                         |
| `switch.tf`          | The switch and gateway ports whose native network is not the LAN, such as the Turing Pi's |
| `clients.tf`         | The fixed addresses of the nodes and the BMC on Servers, and of the smart devices on IoT  |
| `firewall.tf`        | The exceptions to the isolation of IoT, for the apps on `midgard-0` and the LAN           |
| `imports.tf`         | Import blocks that adopt the settings made in the UI                                      |
| `ids.sh`             | Lists the IDs of the managed settings, for imports                                        |

## Applying

Only by hand, from the home network: the provider talks to the gateway at `192.168.1.1`. The state is local
(`terraform.tfstate`, gitignored); if it is lost, the import blocks adopt the settings again.

The API key is `unifi_api_key` in `terraform.tfvars` (gitignored), made in UniFi Network under Settings → Control
Plane → Integrations. Never run `terraform fmt` on the whole directory, as it prints that
file. In the dev container:

```shell
cd terraform/unifi
terraform init && terraform plan
```

Check that a plan only imports and changes what the files declare: an attribute left out keeps its value, a declared
one overwrites the UI. The provider fails an apply when the gateway answers with other values than it sent, and then
marks the resource tainted; declare the value the gateway keeps and `terraform untaint` it.
