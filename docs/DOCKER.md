# Getting started with Docker

This guide will help you to get started with the Decidim-app using Docker. The current Docker compose configuration is not production ready and should be used for development purposes only.

## Prerequisites

* Docker
* Docker Compose
* Git

## Installation

1. Generate a self-signed certificate for HTTPS. You can use the following command to generate a self-signed certificate:

```bash
make tls-cert
```
_You should have a two new files at `$(HOME)/.decidim/tls-certificate/` named `key.pem` and `cert.pem`_

2. Run application using Docker Compose:

```bash
make run
```
_Seeds takes around 10 minutes to be generated, however you can start navigating while seeds are running_

3. If not already done, add MinIO as known host
```bash
echo '127.0.0.1       minio' >> /etc/hosts
```

4. Open your browser and navigate to `https://localhost:3000`
5. MinIO S3 bucket is reachable at ``http://localhost:9000`` with access key `minioadmin` and secret key `minioadmin`

## Known issues

* Direct upload fails and throws an error when uploading an image.
  * Solution: Add `minio` as a host in your `/etc/hosts` file.
* Browser always ask to trust the self-signed certificate
  * Solution: Add permanent trust exception to your browser.