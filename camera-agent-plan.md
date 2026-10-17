# A6 camera agent plan

This plan is designed for a machine that can reach the local LAN.

## Phase 1: Find the device

- Refresh the router DHCP table.
- Check for a MAC address not already bound to a known phone or laptop.
- Check the device name or vendor label.
- Power the camera off and on and compare the DHCP list.

## Phase 2: Lock the IP

- Use the router DHCP reservation/static lease feature.
- Set a fixed IP like 192.168.0.22.
- This is required to keep the camera stable in Home Assistant.

## Phase 3: Validate the device

- Ping the fixed IP.
- Check ARP for the MAC.
- Test common ports: 80, 81, 554, 8080, 8554, 8899.
- Verify the web admin page is available.

## Phase 4: Discover the RTSP stream

- Log into the camera web UI.
- Look for RTSP or ONVIF settings.
- Test common URL patterns such as:
  - rtsp://admin:admin@IP:554/stream1
  - rtsp://admin:admin@IP:554/live
  - rtsp://admin:admin@IP:554/ch00_0
  - rtsp://admin:admin@IP:8554/stream1
- Use ffprobe to validate the URL.

## Phase 5: Add to Home Assistant

- Add the ffmpeg camera platform if RTSP works.
- If not, use go2rtc or a generic camera with a still image and stream source.
- Restart Home Assistant and verify the stream loads.

## Phase 6: Add dashboard card

- Add a Camera card.
- Ensure the stream loads without hangs.
- Optionally add motion or notifications if the device supports them.

## Command bundle

```powershell
ping 192.168.0.22
arp -a | findstr 192.168.0.22
Test-NetConnection 192.168.0.22 -Port 554
Test-NetConnection 192.168.0.22 -Port 8554
Test-NetConnection 192.168.0.22 -Port 80
```

```powershell
ffprobe -v error -rtsp_transport tcp -i "rtsp://admin:admin@192.168.0.22:554/stream1"
```

## Important note

This environment cannot reach your home LAN directly. The actual camera scan has to be run from the machine on your network.
