```

         ___ .___.__  ._______  .______   ____   ____
.___    |   |:   |  \ : .___  \ :_ _   \  \   \_/   /
:   | /\|   ||   :   || :   |  ||   |   |  \___ ___/ 
|   |/  :   ||   .   ||     :  || . |   |  /   _   \ 
|   /       ||___|   | \_. ___/ |. ____/  /___/ \___\
|______/|___|    |___|   :/      :/                  
        :                :       :                   
        :                                            
         whodx: Ephemeral Tor Browser Kiosk
         noVNC over HTTPS | Self-destructs in 30 mins
```

Welcome to **whodx**, a **Docker-based ephemeral kiosk** that launches a **Tor Browser** session accessible via noVNC over HTTPS. This container self-destructs after 30 minutes, leaving no traces behind. Perfect for **quick, private browsing** with zero persistence!

## ⭐ Features

1. **Tor Browser** runs as a cn user.
2. **Xorg dummy driver** provides a virtual display.  
3. **x11vnc** + **noVNC** let you connect via **HTTPS** in your web browser.  
4. **Self-Destruct** after 30 minutes (entrypoint script will stop the container).  
5. **Zero Persistence** unless user explicitly mount volumes.  

> _Note:_ This repo is kept minimal. If you need advanced verification, consider verifying Tor Browser [signatures](https://support.torproject.org/tbb/how-to-verify-signature/). This repo Tor Browser version is hardcoded. (will fix later)


## 📁 Repository Layout

```
whodx/
├── Dockerfile
├── entrypoint.sh
├── xorg-dummy.conf
├── generate-cert.sh
├── tor-browser.install.sh
├── LICENSE
└── README.md
```
- **Dockerfile:** Defines the Debian-based image (Tor, x11vnc, noVNC, etc.).  
- **entrypoint.sh:** Orchestrates everything in a single script (Tor, Xorg, x11vnc, noVNC, kiosk rules).  
- **xorg-dummy.conf:** Xorg config to use a dummy video driver with a set resolution.  
- **generate-cert.sh:** Generates a self-signed cert for HTTPS noVNC (1 Day Expiry).  
- **tor-browser.install.sh:** Fetches Tor Browser from the official Tor Project distribution.  
- **LICENSE:** [MIT License](LICENSE) by default — you can change to your preferred open-source license.  


## 🚀 Quick Start

1. **Clone** the repo:
   ```bash
   git clone https://github.com/0xdx-au/whodx.git
   cd whodx
   ```
2. **Build** the Docker image:
   ```bash
   docker build -t whodx .
   ```
3. **Run** the container:
   ```bash
   docker run --rm -p 9491:8443 whodx
   ```
4. **Access** noVNC:
   - Open [https://localhost:9491/vnc.html](https://localhost:9491/vnc.html)  
   - Accept the self-signed certificate  
   - After ~5–10 seconds, you should see **Tor Browser** within the noVNC interface.  
   - The container will self-terminate in 30 minutes.  

## ⚠️ Notes & Security

- **xhost +** is used in `entrypoint.sh` to disable X authentication, preventing x11vnc crashes but **reducing security**.  *(looking for a workaround currently)*
- **Local scaling**: By default, `-resize` is removed from x11vnc (Debian stable ships x11vnc 0.9.16, which doesn’t support it). Use the noVNC menu for local scaling or “Scale to Fit” instead.  
- **Signature Checks**: We do not verify Tor Browser GPG signatures here. If security is crucial, please add signature verification steps in `tor-browser.install.sh`.  

## 📜 License

Licensed under the [MIT License](LICENSE) — feel free to copy, modify, and share!  

---  

**Enjoy safe, ephemeral browsing!** 👾🔐  
```
