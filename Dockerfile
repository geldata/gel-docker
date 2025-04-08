FROM debian:bookworm-slim
ARG version
ARG exact_version
ARG subdist

ENV GOSU_VERSION=1.11
ENV DEFAULT_OS_USER=gel
ENV DEFAULT_SERVER_BINARY=gel-server-${version}
ENV VERSION=${version}

SHELL ["/bin/bash", "-c"]

RUN set -Eeo pipefail; shopt -s dotglob inherit_errexit nullglob; \
export DEBIAN_FRONTEND=noninteractive; \
(test -n "${version}" || \
  (echo ">>> ERROR: missing required 'version' build-arg" >&2 && exit 1)) \
&& ( \
    for i in $(seq 1 5); do [ $i -gt 1 ] && sleep 1; \
        apt-get update \
    && s=0 && break || s=$?; done; exit $s \
) \
&& ( \
    for i in $(seq 1 5); do [ $i -gt 1 ] && sleep 1; \
        apt-get install -y --no-install-recommends \
            apt-utils \
            gnupg \
            dirmngr \
            curl \
            wget ca-certificates \
            apt-transport-https \
            locales \
            procps \
            gosu \
            jq \
    && s=0 && break || s=$?; done; exit $s \
) \
&& localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8\
&& mkdir -p /usr/local/share/keyrings \
&& curl --proto '=https' --tlsv1.2 -sSf \
    -o /usr/local/share/keyrings/gel-keyring.gpg \
    https://packages.geldata.com/keys/gel-keyring.gpg \
&& echo "deb [signed-by=/usr/local/share/keyrings/gel-keyring.gpg] https://packages.geldata.com/apt bookworm ${subdist:-main}" \
    > "/etc/apt/sources.list.d/gel.list" \
&& ( \
    for i in $(seq 1 5); do [ $i -gt 1 ] && sleep 1; \
        apt-get update \
    && s=0 && break || s=$?; done; exit $s \
) \
&& ( \
    server=gel-server-${version}; \
    [ -n "${exact_version}" ] && server+="=${exact_version}+*"; \
    for i in $(seq 1 5); do [ $i -gt 1 ] && sleep 1; \
        env apt-get install -y "${server}" "${server}-ext-postgis" gel-cli \
    && s=0 && break || s=$?; done; exit $s \
) \
&& ln -s /usr/bin/${package}-${version} /usr/bin/${package} \
&& apt-get remove -y apt-utils gnupg dirmngr wget apt-transport-https \
&& apt-get purge -y --auto-remove \
&& rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.utf8

EXPOSE 5656

VOLUME /var/lib/gel/data

COPY docker-entrypoint-funcs.sh docker-entrypoint.sh /usr/local/bin/
COPY show-secrets.sh /usr/local/bin/gel-show-secrets.sh
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["server"]
