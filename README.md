# Runnel, a brain-dead MP3 streamer

## Introduction

(TODO: philosophy, expected use cases, mp3 directory layout, how information is scaped)
        
## System Requirements  

* Modern Mac OS X or Linux
* perl 5.20 or better

I recommend using plenv (https://github.com/tokuhirom/plenv) for
this project, but it is not required.
        
## Installation

* git clone https://github.com/taskboy3000/runnel.git
* cd runnel
* cpanm --installdeps .
* cp runnel-dist.yml runnel.yml
* edit runnel.yml, point mp3BaseDirectory to the root of your mp3 collection
* run script/runnel daemon -l http://*:3000

## Thank You

This project is built on the excellent MVC framework, Mojolicious (https://mojolicious.org/).

## Running with systemd on Linux

Runnel can be run using the hypnotoad prefork server with systemd for automatic startup and process management.

### Configure the listen port

Edit `runnel.yml` and add a `hypnotoad` section to set the TCP listen port:

```yaml
hypnotoad:
  listen:
    - http://*:8080
```

### Create a systemd service unit

Create `/etc/systemd/system/runnel.service`:

```ini
[Unit]
Description=Runnel MP3 Streaming Server
After=network.target

[Service]
Type=forking
User=runnel
Group=runnel
WorkingDirectory=/path/to/runnel
ExecStart=/path/to/runnel/script/runnel hypnotoad -f /path/to/runnel/script/runnel
ExecStop=/path/to/runnel/script/runnel hypnotoad -s /path/to/runnel/script/runnel
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Enable and start the service

```bash
sudo systemctl daemon-reload
sudo systemctl enable runnel
sudo systemctl start runnel
```

## Copyright

sortable:
    Author: https://github.com/tofsjonas/sortable
    Licenses:
        - Unlicense

All other code:
    Author: Joe Johnston <jjohn@taskboy.com>
    Licenses:
        - CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/legalcode)
