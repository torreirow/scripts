#!/usr/bin/env python3
"""
Zigbee2MQTT Device Status Checker

Haalt de lijst van Zigbee devices op via MQTT en toont een overzicht.

Usage:
    # Eerst devices ophalen:
    timeout 10 docker exec mosquitto mosquitto_sub -h localhost -t 'zigbee2mqtt/bridge/devices' -C 1 > /tmp/z2m_devices.json

    # Dan script runnen:
    ./check_zigbee_devices.py
"""

import json
import sys
from pathlib import Path

def main():
    json_file = Path('/tmp/z2m_devices.json')

    if not json_file.exists():
        print("Error: /tmp/z2m_devices.json niet gevonden!")
        print("\nRun eerst:")
        print("  timeout 10 docker exec mosquitto mosquitto_sub -h localhost -t 'zigbee2mqtt/bridge/devices' -C 1 > /tmp/z2m_devices.json")
        sys.exit(1)

    with open(json_file, 'r') as f:
        devices = json.load(f)

    print(f"Totaal devices: {len(devices)}\n")
    print(f"{'Device':<30} {'Type':<12} {'Model':<35} {'Supported':<10}")
    print("=" * 95)

    coordinators = []
    routers = []
    end_devices = []

    for d in devices:
        dtype = d.get('type', '?')

        if dtype == 'Coordinator':
            coordinators.append(d)
        elif dtype == 'Router':
            routers.append(d)
        elif dtype == 'EndDevice':
            end_devices.append(d)

    # Print coordinator
    for d in coordinators:
        name = d.get('friendly_name', '?')
        model = d.get('definition', {}).get('model', 'N/A')
        supported = "✓" if d.get('supported', False) else "✗"
        print(f"{name:<30} {'Coordinator':<12} {model:<35} {supported:<10}")

    # Print routers
    if routers:
        print("\nRouters (mains powered):")
        for d in routers:
            name = d.get('friendly_name', '?')
            model = d.get('definition', {}).get('model', 'N/A')
            vendor = d.get('definition', {}).get('vendor', '')
            supported = "✓" if d.get('supported', False) else "✗"
            model_str = f"{vendor} {model}" if vendor else model
            print(f"{name:<30} {'Router':<12} {model_str:<35} {supported:<10}")

    # Print end devices
    if end_devices:
        print("\nEnd Devices (battery powered):")
        for d in end_devices:
            name = d.get('friendly_name', '?')
            model = d.get('definition', {}).get('model', 'N/A')
            vendor = d.get('definition', {}).get('vendor', '')
            supported = "✓" if d.get('supported', False) else "✗"
            model_str = f"{vendor} {model}" if vendor else model
            print(f"{name:<30} {'EndDevice':<12} {model_str:<35} {supported:<10}")

    print(f"\nSamenvatting:")
    print(f"  Coordinators: {len(coordinators)}")
    print(f"  Routers:      {len(routers)}")
    print(f"  End Devices:  {len(end_devices)}")
    print(f"  Totaal:       {len(devices)}")

if __name__ == '__main__':
    main()
