# Astroneer for Pterodactyl: custom egg + custom runtime image

This bundle includes:

- `egg-astroneer-dedicated-server-modern.json`
- `Dockerfile.astroneer-ptero`
- `astroneer-start.sh`

## Build the image

From a directory containing the Dockerfile and startup script:

```bash
cp /path/to/Dockerfile.astroneer-ptero ./Dockerfile
cp /path/to/astroneer-start.sh ./astroneer-start.sh
docker build -t ghcr.io/YOURORG/astroneer-ptero:latest .
docker push ghcr.io/YOURORG/astroneer-ptero:latest
```

Then replace `ghcr.io/REPLACE_ME/astroneer-ptero:latest` in the egg JSON with your actual image path before importing the egg.

## Why this exists

The stock Astroneer Pterodactyl egg uses the generic Proton image and starts `proton run ./Astro/Binaries/Win64/AstroServer-Win64-Shipping.exe` directly. Current reports show that setup now crashes on startup with DXVK/Vulkan/Xalia headless display failures. This replacement uses a custom runtime with GE-Proton, Xvfb, SteamCMD, and a bootstrap wrapper that stores all runtime data under `/home/container`.

## Notes

- Encryption is enabled by default. Only disable it for legacy troubleshooting.
- `OWNER_NAME` is required. `OwnerGuid` is set to `0` and Astroneer should populate it when the owner first connects.
- `PUBLIC_IP` can be left blank and will be auto-detected from `https://api.ipify.org`.
- Save data and generated config remain under `/home/container`, which is the persistent Pterodactyl volume.
