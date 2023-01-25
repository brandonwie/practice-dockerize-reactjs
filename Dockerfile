# contain all of the steps we need to customize an image

# we specify a node image so anytime you're customizing an image we have to give it a image that we want to customize
FROM node:19-alpine3.16

# working directory of the container
# anytime we copy any files it's going to run those commands
# and copy those files into this directory so we know that
# anything related to our app is going to be stored in that directory
# so technically we don't need this command for anything
WORKDIR /app

# take the package.json file and copy it into the image
# right and then that way once we copy the package.json file,
# we can do an npm install to install all of our dependencies

# work directory is specified, so either `/app` or `.`
COPY package.json .

# the next thing that we want to do is run an npm install
RUN yarn install

# next thing that i want to do is now copy the rest of all of our code
# or the rest of all of our files into our container
COPY . .

###############################################################################
#! why copy package.json again above?
# an optimization for Docker to build the image faster for future builds
#? installing dependencies is a very expensive operation


#? above codes represents 5 different layers
# Docker builds these images based on these layers
# on build, Docker caches these the result of each layer

# package.json doesn't change that often
# unless we add a new dependency, we can cache the result of two layers,
# `COPY package.json` . and `RUN yarn install`
# and then when we build the image again, Docker will use the cached result

# Docker would have no idea whether we changed our source code or we changed
# the dependencies in our packages.json so every time we ran a copy
# we would have to then do a full npm install
# regardless of whether or not the dependencies change
# so we would be unable to take the cache result

#! so by splitting up the COPY into two, we can ensure that
#! only when we change our package.json, we have to run an npm install

###############################################################################

# The app listens on port 3000 so we want to expose port 3000 and then finally we need to do an yarn start to actually start the development server so we'll type in cmd

EXPOSE 3000
CMD ["yarn", "start"]