FROM debian:bookworm-slim
LABEL maintainer="support@ip2location.com"

# Install packages
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get -qy install curl gnupg wget unzip

# MongoDB setup
RUN curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
RUN echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main" | tee /etc/apt/sources.list.d/mongodb-org-8.0.list
RUN apt-get update
RUN apt-get install -y mongodb-org

# Add scripts
ADD run.sh /run.sh
ADD update.sh /update.sh
RUN chmod 755 /*.sh

# Exposed ENV
ENV TOKEN=FALSE
ENV CODE=FALSE
ENV MONGODB_PASSWORD=FALSE

EXPOSE 27017 27017
CMD ["bash", "/run.sh"]