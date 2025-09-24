# LET OP! DIT IS EEN CHATGPTOEFENVERSIE!

# HostMaster

HostMaster is een volledige WHMCS-clone voor het beheren van VPS en game-servers.  
Het bevat alles wat je nodig hebt om klanten direct te bedienen: betalingen, server provisioning en een moderne webinterface.

## Features

- Frontend in React + Tailwind
- Backend in Node.js + Express
- Stripe Billing integratie
- Virtualizor VPS provisioning
- Pterodactyl game-server provisioning
- Redis queue voor provisioning-taken
- PostgreSQL database
- Docker Compose productie setup
- Nginx reverse proxy + HTTPS (Let’s Encrypt)
- Systemd services voor backend & worker

## Installatie

HostMaster kan direct op een server geïnstalleerd worden met **één script**.  
Je hoeft alleen de essentiële keys en domeinnaam in te voeren.

### Stappen:

1. Open een SSH-verbinding naar je server (Ubuntu/Debian aanbevolen)
2. Voer het installatiescript uit:

```bash
curl -sSL https://raw.githubusercontent.com/<gebruikersnaam>/HostMaster/main/install.sh | bash
