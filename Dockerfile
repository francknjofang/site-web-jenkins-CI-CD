# Build Stage
FROM nginx:1.21.1 as build
RUN apt-get update && \
    apt-get install -y git
RUN git clone https://github.com/francknjofang/static-website-example.git /usr/share/nginx/html

# Final Stage
FROM nginx:1.21.1
LABEL maintainer="Franck Njofang"
COPY --from=build /usr/share/nginx/html /usr/share/nginx/html
CMD ["nginx", "-g", "daemon off;"]
