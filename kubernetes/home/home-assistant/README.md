# Home Assistant

The automations and scripts in `config/`. What is made in the editors of Home Assistant is not in git and not listed
here, see `config/integrations/ui.yaml`.

## Lights (`config/automations/lights`)

| Automation | When | Does |
|---|---|---|
| Sunrise | 08:00 or sunrise | Living room and bedroom lights off |
| Sunset | 1 hour before sunset | Living room and bedroom lights on, 50% |
| Coming home | Arriving home, from 1 hour before sunset until sunrise | Kitchen, bedroom and two living room lights on, 50% warm |
| Leaving home | Leaving home | All lights on the ground floor off |
| Sleep | By hand | Bedroom and living room off, kitchen at 15% |
| Toilet occupied | Motion in the toilet | Toilet light on, 10% from 23:00 to 07:00, else 100% |
| Toilet free | No motion for 15 minutes | Toilet light off |
| Toilet light level | Toilet light on or changed, as after the wall switch | Back to the brightness of Toilet occupied |

## Alerts (`config/automations/alerts`)

Push notifications to the phone.

| Automation | When | Notification |
|---|---|---|
| Water leak | The water meter detects a leak | Critical, sounds on silent |
| Water running | Water flows for an hour without a break | Time-sensitive |
| Backup failed | The automatic backup fails | Normal |
| Backup late | At 12:00, no successful backup for 26 hours | Normal |
| Ventilate | PM2.5 above 50 µg/m³ for 15 minutes, VOC index above 350 for 30 minutes, or humidity above 70% for 30 minutes | Normal |
| Ventilate done | The same readings below their limit for the same time, after Ventilate | Normal |
| Humidify | Humidity below 30% for 2 hours | Normal |
| Humidify done | Humidity above 30% for 30 minutes, after Humidify | Normal |
| Green electricity | CO₂ intensity of the grid below 250 g/kWh for 15 minutes, 08:00 to 21:00, once a day | Normal |
| Washing machine done | Washer plug below 4 W for 10 seconds, with the plug on for at least 5 minutes | Normal |

## Scripts (`config/scripts`)

| Script | Does |
|---|---|
| Turn everything off | All lights on the ground floor off |
| Turn off all lights | All lights with the label `lights` off |
| Toilet | Toilet light on while there is motion, as Toilet occupied, then off |
