FROM alpine:3.14
MAINTAINER Curtis K <curtis@linux.com>

# Run as unprivileged user
ENV USERNAME=itsalwaysdns
ENV GROUP=itsalwaysdns
RUN adduser --disabled-password $GROUP $USERNAME

# Install script dependencies
RUN apk add --no-cache openssl curl bind-tools bash netcat-openbsd whois ncurses

# Add script to home directory of user
USER $USERNAME
WORKDIR /home/$USERNAME
ADD . .

ENV SCRIPT_PATH="/home/${USERNAME}/itsalwaysdns"

ENTRYPOINT ["/home/itsalwaysdns/itsalwaysdns"]