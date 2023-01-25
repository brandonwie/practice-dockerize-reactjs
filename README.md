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

## Build image

```bash
docker build -t react-image .
```

- outside of containers can't talk to containers by default'
- so `EXPOSE 3000` doesn't really do anything else than just exposing the port inside the container

```bash
docker run -d -p 3001:3000 --name react-app react-image
```

- 3001: port on the host machine (poked hole for outside world)
- 3000: port on the container (what port we're going to send traffic to our container')

```mermaid
stateDiagram-v2
    state OutsideOfHostMachine {
        direction RL
        [*] --> HostMachine: Port 3001
        state HostMachine {
            direction RL
            yswsii:React\nContainer
            [*]-->yswsii: Port 3000
        }
        [*] --> HostMachine: Localhost 3000
    }
```

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
