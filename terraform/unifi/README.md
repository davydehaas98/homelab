# unifi

Settings of the UniFi Cloud Gateway Ultra that the cluster depends on, as far as they are managed here. Everything else
stays in the UI.

| File               | Holds                                                                                |
|--------------------|--------------------------------------------------------------------------------------|
| `network.tf`       | The networks: the LAN, the Servers VLAN of the nodes, IPTV, IoT and Guest            |
| `port_forwards.tf` | The port forwards to the public Envoy Gateway and Plex                               |
| `wlan.tf`          | The Wi-Fi networks; only the guest passphrase is set here, from `terraform.tfvars`   |
| `bgp.tf`, `bgp.conf` | The gateway's side of the BGP sessions with Cilium, as FRR config                  |
| `clients.tf`       | The fixed addresses of the nodes on the Servers VLAN                                 |
| `imports.tf`       | Import blocks that adopt the settings made in the UI                                 |
| `ids.sh`           | Lists the IDs of the networks and port forwards, for imports                         |

## Applying

Only by hand, from the home network: the provider talks to the gateway at `192.168.1.1`. The state is local
(`terraform.tfstate`, gitignored); if it is lost, the import blocks adopt the settings again.

The secrets are in `terraform.tfvars` (gitignored): `unifi_api_key`, made in UniFi Network under Settings → Control
Plane → Integrations, and `guest_wifi_passphrase`. Never run `terraform fmt` on the whole directory, as it prints that
file. In the dev container:

```shell
cd terraform/unifi
terraform init && terraform plan
```

Check that a plan only imports and changes what the files declare: an attribute left out keeps its value, a declared
one overwrites the UI. The provider fails an apply when the gateway answers with other values than it sent, and then
marks the resource tainted; declare the value the gateway keeps and `terraform untaint` it.
