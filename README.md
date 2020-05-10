# Docker Compose Configuration For Development & Production

This repository is designed to facilitate development using docker. It can be used in conjunction with projects based 
on a template from the [docker-project](https://github.com/yarbala/docker-project) repository. 

## Features:

1. Simple process of installation and use
1. Unlimited number of projects working simultaneously
1. Integration with Let's Encrypt for automatic certificate installation
1. Uses only official and standard docker images
1. Simultaneous launch and support of different versions of PHP or any other development tools

## Usage

Make sure that docker & docker-compose installed on your system. Make sure that port 80 is open and not in use. 
443 port is optional for SSL encryption. Then clone this project. Copy file ```.env.example``` to ```.env```.

For development environment use:
```dotenv
COMPOSE_FILE=docker-compose.dev.yml
``` 

For production use:
```dotenv
COMPOSE_FILE=docker-compose.prod.yml
``` 

You can leave APP_NETWORK as is or change it to another name. You should use this network name for all projects.
You must use this network name for all images that use this project.

The RESTART_POLICY option must be set to one of the following values:
1. ```no``` If you plan to run this container manually
1. ```always``` If you want to keep this project always running
1. ```on-failure``` For automatic restart only in case of error
1. ```unless-stopped``` If you want to keep the containers running at all times, until you stop them.

Build & run this project.

```bash
cd ~/projects/docker-compose/
docker-compose build
docker-compose up -d
```

Refer to [docker-project](https://github.com/yarbala/docker-project) documentation to setup first project.