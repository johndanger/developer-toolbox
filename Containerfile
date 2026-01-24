FROM scratch AS ctx
COPY / /

FROM quay.io/fedora/fedora:42

# Accept IDE build argument with default value of "all"
ARG IDE=all
ARG LSP=""

# build
RUN --mount=type=bind,from=ctx,src=/,dst=/ctx \
    bash /ctx/scripts/build.sh ${IDE} ${LSP}
