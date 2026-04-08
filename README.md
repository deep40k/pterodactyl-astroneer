# Pterodactyl Astroneer

Astroneer dedicated server image and egg for use with Pterodactyl.

This repository contains:

- a custom Docker image definition for running an Astroneer dedicated server
- a startup script used by the container
- a Pterodactyl egg JSON for importing the server into your panel

## Files

- `Dockerfile`  
  Builds the custom container image

- `astroneer-start.sh`  
  Startup/entrypoint logic for the Astroneer server

- `egg-astroneer-dedicated-server-modern.json`  
  Pterodactyl egg definition

- `README.md`  
  This file

## Goal

The stock Astroneer Pterodactyl egg has had runtime issues with Proton-based headless startup. This project is intended to provide a more reliable path by using a custom image and updated startup flow.

## Build and publish to GHCR

Make sure your `Dockerfile` includes this label near the top:

```dockerfile
LABEL org.opencontainers.image.source="https://github.com/deep40k/pterodactyl-astroneer"
