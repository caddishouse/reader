Mox.defmock(Caddishouse.GoogleMock, for: Caddishouse.OAuth2.Provider)
Application.put_env(:caddishouse, :google_api, Caddishouse.GoogleMock)

Mox.defmock(Caddishouse.StorageMock, for: Caddishouse.Storage)
Application.put_env(:caddishouse, :storage_api, Caddishouse.StorageMock)

ExUnit.start()
{:ok, _} = Application.ensure_all_started(:ex_machina)
Ecto.Adapters.SQL.Sandbox.mode(Caddishouse.Repo, :manual)
