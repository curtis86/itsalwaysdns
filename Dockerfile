FROM alpine:3.14
MAINTAINER Curtis K <curtis@linux.com>

# Run as unprivileged user
ENV USERNAME=itsalwaysdns
ENV GROUP=itsalwaysdns

RUN addgroup $GROUP
RUN adduser $GROUP $USERNAME

# Install script dependencies
RUN apk add --no-cache openssl curl bind-tools bash netcat whois

# Add script to home directory of user
USER $USERNAME
WORKDIR /home/$USERNAME
ADD . .