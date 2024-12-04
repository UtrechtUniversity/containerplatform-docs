FROM python:3.12 AS build
# to ignore the warning in action
ENV PIP_ROOT_USER_ACTION=ignore

RUN pip install mkdocs-material mkdocs-macros-plugin mkdocs-glightbox mkdocs-video

#ADD git@github.com:UtrechtUniversity/containerplatform-docs.git /docs/

#todo make this ssh and set repo to private, but we are waiting for a newer version of docker in the runners so we can use --ssh
#todo https://github.com/actions/actions-runner-controller/issues/2571
#todo set the repo to internal if ssh is fixed https://github.com/UtrechtUniversity/containerplatform-docs/settings
ADD  https://github.com/UtrechtUniversity/containerplatform-docs/archive/dev.tar.gz /dev.tar.gz

RUN mkdir /docs &&  \
    tar -xvf /dev.tar.gz -C /docs &&  \
    cd /docs/containerplatform-docs-dev &&  \
    mkdocs build


FROM nginxinc/nginx-unprivileged:stable-alpine
COPY --from=build --chown=nginx:nginx /docs/containerplatform-docs-dev/site /usr/share/nginx/html

