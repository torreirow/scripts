# Zigbee Troubleshooting - 23 Maart 2026

## Probleem
Na een nette `shutdown -h` om 08:20 en herstart om 17:00 werken ALLE IKEA Zigbee apparaten niet meer.
- Voorzolderlamp reageert niet (brandt wel, maar geen Zigbee controle)
- Alle 14 IKEA apparaten offline sinds ~8:00 vanmorgen
- Tuya outdoorplug werkt WEL (komt automatisch terug na herstart)

## Diagnose
**Coordinator probleem:** Sonoff Zigbee 3.0 USB Dongle Plus start niet op
- Container: `zigbee2mqtt` crasht in boot loop
- Error: Dongle geeft `resetInd` maar reageert niet op verdere commando's
- Logt vast bij: `SREQ: SYS - version` (krijgt geen response)
- Bridge state blijft: `{"state":"offline"}`

**Wat we hebben geprobeerd:**
1. ✗ Zigbee2MQTT restart (meerdere keren)
2. ✓ Dongle fysiek gereset (eruit/erin) - geen effect
3. ✗ Config aanpassing (baudrate, device path) - geen effect
4. ✗ Database reset (fresh start) - geen effect
5. Service momenteel GESTOPT

## Huidige Status
- **Zigbee2MQTT:** GESTOPT (`sudo systemctl stop docker-zigbee2mqtt.service`)
- **Database:** INTACT op `/var/lib/zigbee2mqtt/database.db`
- **Backup:** `/var/lib/zigbee2mqtt/database.db.before-reset-*`
- **Dongle:** Zit in USB poort, wijst naar `/dev/ttyUSB1` via `/dev/zigbee`
- **Alle apparaten:** Nog in database (17 devices), maar offline

## Root Cause
Identiek aan probleem van 29 januari 2026 (zie `ZIGBEE_MIGRATION_LOG.md`):
> USB adapter in "stuck" staat na reboot
> USB stack moet volledig gereset worden

## Volgende Stap: SERVER REBOOT
Dit werkte in januari. Na reboot:

### Check-list na reboot:
1. Check of dongle herkend wordt:
   ```bash
   ls -la /dev/zigbee /dev/ttyUSB*
   readlink -f /dev/serial/by-id/usb-Silicon_Labs_Sonoff_Zigbee_3.0_USB_Dongle_Plus_0001-if00-port0
   ```

2. Start Zigbee2MQTT:
   ```bash
   sudo systemctl start docker-zigbee2mqtt.service
   ```

3. Monitor logs:
   ```bash
   docker logs zigbee2mqtt --tail 50 -f
   ```

4. Check bridge state:
   ```bash
   timeout 5 docker exec mosquitto mosquitto_sub -h localhost -t 'zigbee2mqtt/bridge/state' -C 1
   ```
   Verwacht: `{"state":"online"}`

5. Als online, trigger IKEA router devices (mains powered):
   - voorzolderlamp - stekker eruit/erin
   - aanrechtlamp - stekker eruit/erin
   - eetkamerlampen (1,2,3) - stekker eruit/erin
   - geurwerkkamerplug - stekker eruit/erin
   - bloembakkeukenplug - stekker eruit/erin

6. Druk op batterij knoppen om ze wakker te maken

### Als reboot NIET werkt:
**Plan B: Andere USB poort**
1. Stop service: `sudo systemctl stop docker-zigbee2mqtt.service`
2. Dongle in andere USB poort
3. Check nieuwe device: `ls -la /dev/serial/by-id/ | grep Sonoff`
4. Update symlink indien nodig in `/modules/hassio/default.nix` (udev rule)
5. `sudo nixos-rebuild switch --flake .#malandro`

**Plan C: Firmware flash**
- Guide: https://github.com/Koenkk/Z-Stack-firmware/tree/master/coordinator/Z-Stack_3.x.0/bin
- Tool: https://github.com/JelmerT/cc2538-bsl

## Configuratie Info
- **Zigbee2MQTT versie:** 2.7.2
- **Config:** `/var/lib/zigbee2mqtt/configuration.yaml`
- **Database:** `/var/lib/zigbee2mqtt/database.db`
- **Logs:** Docker container `zigbee2mqtt`
- **MQTT broker:** `mosquitto` (poort 1883)
- **Frontend:** https://zigbee2mqtt.toorren.net (poort 8086)
- **Home Assistant:** https://homeassistant.toorren.net (poort 8123)

## Zigbee Network Settings
- **Channel:** 11
- **PAN ID:** 6754 (0x1A62)
- **Extended PAN ID:** [221,221,221,221,221,221,221,221]
- **Coordinator IEEE:** 0x00124b0029dc09f4
- **Adapter:** zstack (Sonoff Zigbee 3.0 USB Dongle Plus)

## Apparaten (17 totaal)
**Router devices (8):**
- Coordinator
- 2x TRADFRI Driver 10W (aanrechtlamp, voorzolderlamp)
- 3x TRADFRI bulb E27 (eetkamerlampen)
- 2x TRETAKT Smart plug (geurwerkkamer, bloembak)
- 1x Tuya TS011F (outdoorplug) ← **ENIGE DIE WERKT**

**End devices (8):**
- 5x IKEA RODRET knoppen
- 1x IKEA TRADFRI on/off switch
- 1x IKEA Remote Control N2
- 2x Sensoren (deur, WC)

## ✅ OPLOSSING: SERVER REBOOT

**Datum:** 23 maart 2026, ~22:07

Na een volledige server reboot (`sudo reboot`) kwam de Zigbee2MQTT service automatisch weer online:
- Service gestart om 22:07:17 CET
- Bridge state: `{"state":"online"}` ✓
- Dongle: `/dev/zigbee -> ttyUSB0` (correct herkend)
- **Alle 17 devices nu bereikbaar!**

### Verificatie

```bash
# Devices ophalen en checken
timeout 10 docker exec mosquitto mosquitto_sub -h localhost -t 'zigbee2mqtt/bridge/devices' -C 1 > /tmp/z2m_devices.json
python3 ~/data/git/torreirow/scripts/homeassistant/check_zigbee_devices.py
```

**Resultaat:** Alle apparaten online
- 8 Routers (mains powered) - inclusief alle IKEA apparaten ✓
- 8 End devices (battery powered) ✓
- 1 Coordinator ✓

### Conclusie

**Root cause bevestigd:** USB adapter in "stuck" staat na shutdown/herstart.
**Oplossing:** Volledige server reboot reset de USB stack.

Dit is het **tweede incident** met hetzelfde probleem:
1. **29 januari 2026:** Eerste keer, opgelost met server reboot
2. **23 maart 2026:** Tweede keer, opgelost met server reboot

**Pattern:** Server shutdown gevolgd door herstart triggert USB dongle hang. Zigbee2MQTT container restart helpt NIET. Alleen volledige server reboot lost het op.

## Datum/Tijd
- **Probleem begon:** 23 maart 2026, ~08:00
- **Troubleshooting:** 23 maart 2026, 21:00-21:45
- **Server shutdown was:** 23 maart 2026, 08:20
- **Server herstart was:** 23 maart 2026, ~17:00
- **Reboot oplossing:** 23 maart 2026, 22:07
