FROM alpine:3.20
RUN --mount=type=cache,target=/var/cache/apk,sharing=locked apk add rsync
COPY --link . /home/
CMD ["rsync","-aP","/home/","/home/"]
