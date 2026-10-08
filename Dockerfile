# Step 1: Build the Vue application
FROM node:lts-alpine AS build-stage
WORKDIR /web-app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Step 2: Build Production ready build using nginx
FROM nginx:stable-alpine AS production-stage
COPY --from=build-stage /web-app/dist /usr/share/nginx/html
# Expose 80 to the container. 
EXPOSE 80   
CMD ["nginx", "-g", "daemon off;"]



