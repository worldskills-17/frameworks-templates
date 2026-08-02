# go (gin) - builds fully offline from the committed vendor/ directory.
# GOPROXY=off + -mod=vendor guarantee no network module fetches at build time.
FROM golang:1.23-alpine AS build
WORKDIR /app
ENV GOFLAGS=-mod=vendor GOPROXY=off CGO_ENABLED=0
COPY . .
RUN go build -trimpath -o /app/server .

FROM alpine:3.20
WORKDIR /app
COPY --from=build /app/server /app/server
EXPOSE 80
CMD ["/app/server"]
