FROM golang:alpine as build

WORKDIR /opt/app-root
ENV GOPATH=/opt/app-root/
COPY src src
WORKDIR /opt/app-root/src/port-check/
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o portcheck

FROM scratch

WORKDIR /opt/app-root
COPY --from=build /opt/app-root/src/port-check/portcheck /opt/app-root/portcheck


EXPOSE 8080
CMD ["/opt/app-root/portcheck"]
ENTRYPOINT ["/opt/app-root/portcheck"]