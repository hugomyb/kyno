FROM ghcr.io/cirruslabs/flutter:latest

WORKDIR /app

# Tools required by deploy script
RUN apt-get update \
    && apt-get install -y --no-install-recommends git rsync bash \
    && rm -rf /var/lib/apt/lists/*

ARG GITHUB_TOKEN
ARG GH_TOKEN
ARG GITHUB_PAT
ENV GITHUB_TOKEN=${GITHUB_TOKEN}
ENV GH_TOKEN=${GH_TOKEN}
ENV GITHUB_PAT=${GITHUB_PAT}

COPY . .

RUN chmod +x scripts/deploy_gh_pages.sh \
    && chmod +x scripts/patch_flutter_service_worker_for_push.sh \
    && ./scripts/deploy_gh_pages.sh

CMD ["sh", "-c", "sleep infinity"]
