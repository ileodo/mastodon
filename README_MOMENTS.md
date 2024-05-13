# README for moments.dong.page Instance

## Image Build

```sh
# Create Docker Builder
docker buildx create --name multiarch --driver docker-container --use

# Build Dev images (Same command can be used to build live image)
docker buildx build --tag gitea.hc.ileodo.com/leodong/mastodon:moments-dev -o type=image --platform=linux/arm64,linux/amd64 . --push
docker buildx build --tag gitea.hc.ileodo.com/leodong/mastodon-streaming:moments-dev -o type=image --platform=linux/arm64,linux/amd64 . -f streaming/Dockerfile --push
```

## Deployment

## Migrate DB

```sh
docker-compose run --rm web bundle exec rake db:migrate
```
