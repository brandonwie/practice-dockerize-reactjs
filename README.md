# Docker + ReactJS tutorial

> Development to Production workflow + multi-stage builds + docker compose

## Create Dockerfile

> contain all of the steps we need to customize an image

```dockerfile
# Dockerfile
FROM node:19-alpine3.16
WORKDIR /app
COPY package.json .
RUN yarn install
COPY . .
EXPOSE 3000
CMD ["yarn", "start"]
```

```dockerfile
FROM node:19-alpine3.16
```

- we specify a node image so anytime you're customizing an image we have to give it a image that we want to customize

```dockerfile
WORKDIR /app
```

- working directory of the container
- anytime we copy any files it's going to run those commands and copy those files into this directory<br> so we know that
  anything related to our app is going to be stored in that directory
- so technically we don't need this command for anything

```dockerfile
COPY package.json .
```

- take the package.json file and copy it into the image
- right and then that way once we copy the package.json file,
- we can do an npm/yarn install to install all of our dependencies
- work directory is specified, so either `/app` or `.`

```dockerfile
RUN yarn install
```

- the next thing that we want to do is run an npm install

```dockerfile
COPY . .
```

- next thing that you want to do is now copy the rest of all of our code or the rest of all of our files into our container

### why copy package.json again above?

- an optimization for Docker to build the image faster for future buildsk
- installing dependencies is a very expensive operation
- **each line represents a layer, so above codes represents 5 different layers**
- Docker builds these images based on these layers
- on build, Docker caches these the result of each layer
- package.json doesn't change that often unless we add a new dependency, we can cache the result of two layers,

### `COPY package.json` . and `RUN yarn install` (the two layers)

- and then when we build the image again, Docker will use the cached result
- Docker would have no idea whether we changed our source code or we changed the dependencies in our packages.json so every time we ran a copy we would have to then do a full npm install regardless of whether or not the dependencies change so we would be unable to take the cache result
- therefore, by splitting up the COPY into two, we can ensure that only when we change our package.json, we have to run an npm install

```dockerfile
EXPOSE 3000
CMD ["yarn", "start"]
```

- The app listens on port 3000 so we want to expose port 3000 and then finally we need to do an yarn start to actually start the development server so we'll type in cmd

---

## Build image

```bash
docker build -t react-image .
```

- outside of containers can't talk to containers by default'
- so `EXPOSE 3000` doesn't really do anything else than just exposing the port inside the container

```bash
docker run -d -p 3001:3000 --name react-app react-image
```

- `-d`: run in detached mode (run in the background)
- `-p`: port forwarding (forwarding port from the host machine to the container)
- `--name`: name of the container

- 3001: port on the host machine (poked hole for outside world)
- 3000: port on the container (what port we're going to send traffic to our container')

---

## Docker networking - forwarding ports

```mermaid
stateDiagram-v2
    state OutsideOfHostMachine {
        direction RL
        [*] --> HostMachine: Port 3001
        [*] --> HostMachine: Localhost 3000
        state HostMachine {
            direction RL
            yswsii:React\nContainer
            [*]-->yswsii: Port 3000
        }
    }
```

<br>

```mermaid
stateDiagram-v2
    Chrome
    state DockerReactContainer {
        state ReactDevServer {
            index.html
            CSS
            JS
        }
    }
    direction LR
    Chrome --> DockerReactContainer: Port 3000
    DockerReactContainer --> Chrome: Port 3000
```

---

## dockerignore files

> prevent unnecessary files from being copied into the image

```bash
docker exec -it react-app sh # or bash
```

- `docker exec`: run a command in a running container
- `-it`: interactive terminal
- `react-app`: container name
- `sh` or `bash`: shell (not every image is using the bash shell)

```properties
# .dockerignore
node_modules
Dockerfile
.git
.gitignore
.dockerignore
```

### Remove previous container, rebuild image, and run container

```bash
docker stop react-app
docker rm react-app # `-f` to force remove if don't skip stop

docker build -t react-image .
docker run -d -p 3001:3000 --name react-app react-image
```

### Go to shell in the container and check if the target files are ignored properly

```bash
docker exec -it react-app sh
```

```sh
ls -a
```

---

## 3 ways to Manage data in Docker container to sync src code

There are three types of mounts, `bind`, `volume`, and `tmpfs`.

By default, all files created inside a container are stored on a writable container layer. This means that:

- The data doesn’t persist when that container no longer exists, and it can be difficult to get the data out of the container if another process needs it.

- A container’s writable layer is tightly coupled to the host machine where the container is running. You can’t easily move the data somewhere else.

- Writing into a container’s writable layer requires a storage driver to manage the filesystem. The storage driver provides a union filesystem, using the Linux kernel. This extra abstraction reduces performance as compared to using data volumes, which write directly to the host filesystem.

**Docker has two options for containers to store files on the host machine**, so that the files are persisted even after the container stops: volumes, and bind mounts.

Docker also supports containers storing files in-memory on the host machine. Such files are not persisted. If you’re running Docker on Linux, tmpfs mount is used to store files in the host’s system memory. If you’re running Docker on Windows, named pipe is used to store files in the host’s system memory.

[from Docker documentation](https://docs.docker.com/storage/)

---

## Comparisons of the three

![Volumes](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/b9l9lgibwh8dwhwdzp0x.png)

### [Volumes](https://docs.docker.com/storage/volumes/)

> Volumes are the preferred mechanism for persisting data generated by and used by Docker containers. While bind mounts are dependent on the directory structure and OS of the host machine, volumes are completely managed by Docker.

---

![Bind mount](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/jxbnzehw1k3x5vz3flmz.png)

### [Bind mounts](https://docs.docker.com/storage/bind-mounts/)

> Bind mounts have been around since the early days of Docker. Bind mounts have limited functionality compared to volumes. When you use a bind mount, a file or directory on the host machine is mounted into a container. The file or directory is referenced by its absolute path on the host machine.
>
> By contrast, when you use a volume, a new directory is created within Docker’s storage directory on the host machine, and Docker manages that directory’s contents.

---

![tmpfs mount](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/mqvcf41ypxyc9j4r799f.png)

### [tmpfs mounts](https://docs.docker.com/storage/tmpfs/)

> If you’re running Docker on Linux, you have a third option: tmpfs mounts. When you create a container with a tmpfs mount, the container can create files outside the container’s writable layer.
>
> As opposed to volumes and bind mounts, a tmpfs mount is temporary, and only persisted in the host memory. When the container stops, the tmpfs mount is removed, and files written there won’t be persisted.

---

## Enough with explanations, let's continue.

### Bind mounts

> Sanjeev uses bind mounts, so here, we're just gonna use it

Stop container

```bash
docker rm react-app -f
```

And run the container with bind mounts

```bash
docker run -v $(pwd):/app -d -p 3001:3000 --name react-app react-image
```

- `-v`: bind mount (also can be volumes depending on the first field)

  - `-v dirlocaldirectory:containerdirectory`
  - `-v $(pwd):/app`: bind mount the current working directory to the `/app` directory in the container
  - you can only sync `src` folder

- [Official document](https://docs.docker.com/storage/bind-mounts/) recommend new users use `--mount` instead of `--volume | -v` when bind mounts because it give a way clear readability.

```bash
docker run --mount type=bind,source="$(pwd)",target=/app -d -p 3001:3000 --name react-app react-image
```

- the documentation shows **Volumes** and **Bind mounts** both use `-v` flag, only the difference is the first field:
  - for Volumes: In the case of named volumes, the first field is the name of the volume, and is unique on a given host machine. For anonymous volumes, the first field is omitted.
  - for Bind mounts: In the case of bind mounts, the first field is the path to the file or directory on the host machine.

---

### Hot Reload

To enable `HMR(Hot Module Replacement)`,<br>
add `CHOKIDAR_USEPOLLING=true` as ENV to your Dockerfile

[What is chokidar anyway?](https://www.npmjs.com/package/chokidar): Minimal and efficient cross-platform file-watching library

```dockerfile
...
...
ENV CHOKIDAR_USEPOLLING=true
COPY . .
...
```

or you can add it to your `docker run` command with `-e` flag

```bash
 docker run -e CHOKIDAR_USEPOLLING=true -v $(pwd):/app -d -p 3001:3000 --name react-app react-image
```

### (important) Hot Reload issue with CRA v5.0 (I used V5.0.1)

#### [CRA 5.0 fails to hot-reload in a docker container](https://github.com/facebook/create-react-app/issues/11879#issuecomment-1072162532)

1. Create `setup.js` file in the root directory

   ```js
   // setup.js
   const fs = require('fs');
   const path = require('path');

   if (process.env.NODE_ENV === 'development') {
     const webPackConfigFile = path.resolve(
       './node_modules/react-scripts/config/webpack.config.js'
     );
     let webPackConfigFileText = fs.readFileSync(webPackConfigFile, 'utf8');

     if (!webPackConfigFileText.includes('watchOptions')) {
       if (webPackConfigFileText.includes('performance: false,')) {
         webPackConfigFileText = webPackConfigFileText.replace(
           'performance: false,',
           "performance: false,\n\t\twatchOptions: { aggregateTimeout: 200, poll: 1000, ignored: '**/node_modules', },"
         );
         fs.writeFileSync(webPackConfigFile, webPackConfigFileText, 'utf8');
       } else {
         throw new Error(`Failed to inject watchOptions`);
       }
     }
   }
   ```

2. Change `start` script in `package.json`

   ```json
   "scripts": {
    "start": "node ./setup && react-scripts start",
    ...
   },
   ```

3. Set `WDS_SOCKET_PORT` to the current port as ENV on Dockerfile

```properties
...
ENV CHOKIDAR_USEPOLLING=true
ENV WDS_SOCKET_PORT=3001
COPY . .
...
```

or you can add it to the `docker run` command with `-e` flag

```bash
docker run -e WDS_SOCKET_PORT=3001 -v $(pwd):/app -d -p 3001:3000 --name react-app react-image
```

- otherwise, you'll see `WebSocketClient.js:16 WebSocket connection to 'ws://localhost:3001/ws' failed:` error on your console

4. Remove the running container and re-run it.

```bash
docker rm react-app -f

docker run -v $(pwd):/app -d -p 3001:3000 --name react-app react-image
```

### NOW YOU HAVE UP AND RUNNING DOCKER CONTAINER WITH HOT RELOAD

---

## Bind Mounts Readonly

because the current setting won't stop the container write to the host machine(local machine), and this is not necessary, so we can make the bind mount readonly

```bash
# using volume flag: insert `:ro` after destination directory
docker run -e CHOKIDAR_USEPOLLING=true -v $(pwd):/app:ro -d -p 3001:3000 --name react-app react-image
# using mount flag: add `,readonly` in type
docker run -e CHOKIDAR_USEPOLLING=true --mount type=bind,source="$(pwd)",target=/app,readonly -d -p 3001:3000 --name react-app react-image
```

now container can't write to the host machine

```sh
➜ docker exec -it react-app sh
$ cd src
$ touch hello
touch: hello: Read-only file system
```

## Environment variables

---

## Create React App Readme

This project was bootstrapped with [Create React App](https://github.com/facebook/create-react-app).
In the project directory, you can run:

### `npm start`

Runs the app in the development mode.\
Open [http://localhost:3000](http://localhost:3000) to view it in the browser.

The page will reload if you make edits.\
You will also see any lint errors in the console.

### `npm test`

Launches the test runner in the interactive watch mode.\
See the section about [running tests](https://facebook.github.io/create-react-app/docs/running-tests) for more information.

### `npm run build`

Builds the app for production to the `build` folder.\
It correctly bundles React in production mode and optimizes the build for the best performance.

The build is minified and the filenames include the hashes.\
Your app is ready to be deployed!

See the section about [deployment](https://facebook.github.io/create-react-app/docs/deployment) for more information.

### `npm run eject`

**Note: this is a one-way operation. Once you `eject`, you can’t go back!**

If you aren’t satisfied with the build tool and configuration choices, you can `eject` at any time. This command will remove the single build dependency from your project.

Instead, it will copy all the configuration files and the transitive dependencies (webpack, Babel, ESLint, etc) right into your project so you have full control over them. All of the commands except `eject` will still work, but they will point to the copied scripts so you can tweak them. At this point you’re on your own.

You don’t have to ever use `eject`. The curated feature set is suitable for small and middle deployments, and you shouldn’t feel obligated to use this feature. However we understand that this tool wouldn’t be useful if you couldn’t customize it when you are ready for it.

## Learn More

You can learn more in the [Create React App documentation](https://facebook.github.io/create-react-app/docs/getting-started).

To learn React, check out the [React documentation](https://reactjs.org/).
