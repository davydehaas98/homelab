# devopsarr

Settings of Sonarr, Radarr, Lidarr and Prowlarr in the `media-server` namespace, as far as they differ from the
defaults. Settings left out here are managed in the apps' UI.

## Files

| File                  | Holds                                                                                          |
|-----------------------|------------------------------------------------------------------------------------------------|
| `sonarr.tf`           | Root folder, naming, media management, SABnzbd, delay profile, Discord, Plex metadata, quality definitions |
| `radarr.tf`           | Root folder, naming, media management, SABnzbd, delay profile, Discord, quality definitions   |
| `lidarr.tf`           | Root folder, naming, media management, Discord                                                 |
| `prowlarr.tf`         | The apps Prowlarr syncs its indexers to, the Usenet sync profile and the NZBgeek indexer       |
| `custom_formats.tf`   | Custom formats of Sonarr and Radarr with their score per quality profile                       |
| `quality_profiles.tf` | The `1080p/720p` and `2160p` quality profiles of Sonarr and Radarr                             |
| `env.sh`              | Exports the secrets as `TF_VAR_*`, see below                                                   |
| `imports.tf`          | Import blocks that adopt the settings made in the UI                                           |

Indexers reach Sonarr, Radarr and Lidarr through the Prowlarr sync only. The Lidarr provider is behind on Lidarr's API
and crashes on its delay profile and download clients, so those stay in the UI.

## Scoring

Releases are ranked by quality first, then by the summed scores of their custom formats, then by how close their size is
to the preferred size of the quality definition. Surround sound weighs most, then HEVC, then 10 bit and HDR; HDR weighs
more in the 2160p profile. A score of -10000 blocks a release. Upgrades stop at the cutoff with a score of 60, which
includes the Multi Audio score below, and need a gain of at least 10. The cutoff is WEB for series and Blu-ray for
movies. Formats scored 0 are left out of a profile, as the apps drop them.

Both apps allow the original language and English. For series and movies in another language, releases with both
score 25 more, and the cutoff waits for one; for English ones every release has both.

The regexes match release and file names. Test a change against the release titles in the apps' history before
applying it.

## Applying

Only by hand, there is no CI. The state is local (`terraform.tfstate`, gitignored) and holds the secrets in plain text.
If it is lost, the import blocks adopt the settings again on the next apply.

In the dev container, with the kubeconfig mounted:

```shell
cd terraform/devopsarr
. ./env.sh
terraform init && terraform plan
```

`env.sh` reads the API keys and webhooks from the cluster and asks for the NZBgeek key, which Prowlarr only returns
masked. The providers use the public hostnames, whose `/api` skips the Authentik login. As the APIs return no secrets,
the first apply after an import writes them again. A change made in the UI shows as drift in the next plan.
