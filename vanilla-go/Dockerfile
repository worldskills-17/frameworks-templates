# vanilla-go - stdlib-only Go web app. Builds fully offline (no deps to fetch).
FROM golang:1.23-alpine AS build
WORKDIR /app
# Disable network module fetches - this template has no external dependencies.
ENV GOFLAGS=-mod=mod GOPROXY=off
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -o /app/server .

FROM alpine:3.20
WORKDIR /app
COPY --from=build /app/server /app/server
EXPOSE 80
CMD ["/app/server"]
