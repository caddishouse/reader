# Caddishouse
Caddishouse is a web-based document reader. It connects to your cloud-based storage accounts and lets you import documents to read. You can use it by accessing https://www.caddishouse.com OR set it up locally.

It does the following:
* Access your documents in any number of cloud-based storage accounts quickly.
* Saves the current page you're on for each document.
* Uses less bandwidth/CPU/memory than current readers (TBD, see issue: (TODO)) and loads faster.

In order to support this last requirement, it gives up the following features which many other document readers support (these may be implemented at a future point):
* It is not possible to search a document
* It is not possible to select/copy text
* Annotations are not supported

See ROADMAP for planned features.

## Screenshot
![image](https://user-images.githubusercontent.com/17934/190648629-54172cb9-16b3-47be-a711-4b80025f834c.png)

## Quick Start

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`
  * Start your Minio server (see Set-up Minio), or configure an alternative (see Configuration).

Now you can visit [`localhost:3333 `](http://localhost:3333) from your browser.

## Configuration
```
# ENVARS
MINIO_HOST=localhost
MINIO_PORT=9001
MINIO_ACCESS_KEY=<must be set>
MINIO_SECRET_KEY=<must be set>
ASSET_URL=http://localhost:9001

GOOGLE_OAUTH_CLIENT=<no default, will not throw error if unset>
GOOGLE_OAUTH_SECRET=<no default, will not throw error if unset>
GOOGLE_OAUTH_REDIRECT_URL=http://localhost:3333/auth/google/callback
```

In addition, it's possible to add/implement your own storage solution. While using S3 intead of Minio is simply pointing the host/port/keys to your S3 set-up, you could use an alternative storage solution by implementing the `Caddishouse.Storage` behaviour found in `lib/caddishouse/storage/storage.ex`.

You must then add the following to the config:
```elixir
config :caddishouse,
  storage_api: Your.Storage.Module
```

### Adding/removing providers (TODO)
This configuration has yet to be implemented.

## Set-up Minio
```sh
# For MacOSX
$ brew install --cask docker 

$ docker run \
           -p 9000:9000 \
           -p 9001:9001 \
           -e "MINIO_ROOT_USER=admin" \
           -e "MINIO_ROOT_PASSWORD=admin" \
           quay.io/minio/minio server /data --console-address ":9001"
```

Access http://localhost:9001/buckets, create a bucket called `uploads`.
Go to http://localhost:9001/identity/account, create a service account.

See Configuration.

## Gotchas
### When committing, I get an error that there are dependencies that are out of sync.
Run the following: `mix git_hooks.install`
