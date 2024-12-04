# Build Stage
FROM python:3.12 AS build

# Ignore the warning in pip actions
ENV PIP_ROOT_USER_ACTION=ignore

# Install MkDocs and required plugins
RUN pip install mkdocs-material mkdocs-macros-plugin mkdocs-glightbox mkdocs-video

# Set working directory and copy local files
WORKDIR /app
COPY . /app

# Build the MkDocs documentation
RUN mkdocs build

# Serve Stage
FROM nginxinc/nginx-unprivileged:stable-alpine
COPY --from=build --chown=nginx:nginx /app/site /usr/share/nginx/html