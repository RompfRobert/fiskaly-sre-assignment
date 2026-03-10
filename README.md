# fiskaly-sre-assignment

Take home assignment for Site Reliability Engineer role at fiskaly.

## Task 1: Docker Hello World Web App

This repository includes a minimal Python HTTP app that responds with `Hello World` on port `8080`.

### Build the image

```bash
docker build -t hello-world-web .
```

### Run the container

```bash
docker run --rm --name hello-world-web -p 8080:8080 hello-world-web
```

### Verify locally

```bash
curl http://localhost:8080
```

Expected response:

```text
Hello World
```

### Access from other devices on the same network

By default, `-p 8080:8080` publishes the container port on all host interfaces. To access it from another device on the same network, use:

```text
http://<your-host-ip>:8080
```

Example:

```text
http://192.168.1.42:8080
```
