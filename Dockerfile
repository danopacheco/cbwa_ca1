FROM alpine:latest AS builder

# Install all dependencies required for compiling busybox
RUN apk add gcc musl-dev make perl

# Download busybox sources
RUN wget https://busybox.net/downloads/busybox-1.35.0.tar.bz2 \
  && tar xf busybox-1.35.0.tar.bz2 \
  && mv /busybox-1.35.0 /busybox
  
# Create a non-root user to own the files and run our server
RUN adduser -D static

# Download CA1 from GitHub
RUN wget https://github.com/danopacheco/CA1-Daniel-Pacheco-/archive/main.tar.gz \
  && tar xf main.tar.gz \
  && rm main.tar.gz \
  && mv /CA1-Daniel-Pacheco--main /home/static

# Change working directory
WORKDIR /busybox

# Copy the busybox build config (limited to httpd)
COPY .config .

# Compile and install busybox
RUN make && make install

# Switch to the scratch image
FROM scratch

# Expose container port
EXPOSE 8080

# Copy user and custom BusyBox version to the scratch image
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /busybox/_install/bin/busybox /

# Copying the content of Web CA1 to the scratch image
COPY --from=builder /home/static /home/static

# Change to static user
USER static

## Change working directory
WORKDIR /home/static/CA1-Daniel-Pacheco--main

# httpd.conf 
COPY httpd.conf .

# Issuing commands to run when container is created
CMD ["/busybox", "httpd", "-f", "-v", "-p", "8080", "-c", "httpd.conf"]