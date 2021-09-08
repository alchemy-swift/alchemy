# Deploying

- [DigitalOcean](#digitalocean)
  * [Install Swift](#install-swift)
  * [Run Your App](#run-your-app)
- [Docker](#docker)
  * [Create a Dockerfile](#create-a-dockerfile)
  * [Build and deploy the image](#build-and-deploy-the-image)

While there are many ways to deploy your Alchemy app, this guide focuses on deploying to a Linux machine with DigitalOcean and deploying with Docker.

## DigitalOcean

Deploying with DigitalOcean is simple and cheap. You'll just need to create a droplet, install Swift, and run your project.

First, create a new droplet with the image of your choice, for this guide we'll use `Ubuntu 20.04 (LTS) x64`. You can see the supported Swift [platforms here](https://swift.org/download/#releases).

### Install Swift

Once your droplet is created, ssh into it and install Swift. Start by installing the required dependencies.

```shell
sudo apt-get update
sudo apt-get install clang libicu-dev libatomic1 build-essential pkg-config zlib1g-dev
```

Next, install Swift. You can do this by right clicking the name of your droplet image on the [Swift Releases](https://swift.org/download/#releases) page and copying the link.

Download and decompress the copied link...

```shell
wget https://swift.org/builds/swift-5.4.2-release/ubuntu2004/swift-5.4.2-RELEASE/swift-5.4.2-RELEASE-ubuntu20.04.tar.gz
tar xzf swift-5.4.2-RELEASE-ubuntu20.04.tar.gz
```

Put Swift somewhere easy to link to, such as a folder `/swift/{version}`.
```swift
sudo mkdir /swift
sudo mv swift-5.4.2-RELEASE-ubuntu20.04 /swift/5.4.2
```

Then create a link in `/usr/bin`.
```shell
sudo ln -s /swift/5.4.2/usr/bin/swift /usr/bin/swift
```

Verify that it was installed correctly.

```shell
swift --version
```

### Run Your App

Now that Swift is installed, you can just run your app.

Start by cloning it

```shell
git clone <project>
```

Make sure to allow HTTP through your droplet's firewall
```
sudo ufw allow http
```

Then run it. Note that since we're on Linux we'll need to pass `--enable-test-discovery`, the executable name of your server (`Backend` if you cloned a quickstart), and a custom host and port so that the server will listen on your droplet's IP at port 80.

```shell
cd my-project
swift run --enable-test-discovery Backend --host <droplet-public-ip> --port 80
```

Assuming you had something like this in your `Application.boot`
```swift
get("/hello") {
    "Hello, World!"
}
```

Visit `<droplet-public-ip>/hello` in your browser and you should see 

```
Hello, World!
```

Congrats, your project is live!

**Note** When you're ready to run a production version of your app, add a couple flags to the `swift run` command to speed it up and enable debug symbols for crash traces. You might just want to run these flags every time so it's less to think about.

```shell
swift run -c release -Xswiftc -g
```

## Docker

You can use Docker to create an image that will be deployable anywhere Docker is usable.

### Create a Dockerfile

Start off by creating a `Dockerfile`. This is a file that tells Docker how to build & run an image with your server.

Here's a sample one to copy and paste. Note that you may have to change `Backend` to the name of your executable product.

This file tells docker to use a base image of `swift:latest`, build your project, and, when the image is run, run your executable on host 0.0.0.0 at port 3000

```dockerfile
FROM swift:latest
WORKDIR /app
COPY . .
RUN swift build -c release -Xswiftc -g
RUN mkdir /app/bin
RUN mv `swift build -c release --show-bin-path` /app/bin
EXPOSE 3000
ENTRYPOINT ./bin/release/Backend --host 0.0.0.0 --port 3000
```

### Build and deploy the image

Now build your image. If you've been running your project from the CLI, there may be a hefty `.build` folder. You might want to nuke that before running `docker build` so that you don't need to wait to pass that unneeded directory to Docker.

```shell
$ docker build .
...
Successfully built ab21d0f26ecd
```

Finally, run the built image. Pass in `-d` to tell Docker to run your image in the background and `-p 3000:3000` to tell it that your container's 3000 port should be exposed to your machine.

```shell
docker run -d -p 3000:3000 ab21d0f26ecd
```

Visit `http://0.0.0.0:3000/hello` in the browser and you should see 

```
Hello, World!
```

Awesome! You're ready to deploy with Docker.

_Up next: [Under The Hood](12_UnderTheHood.md)_

_[Table of Contents](/Docs#docs)_
