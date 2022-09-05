defmodule Caddishouse.OAuth2.Provider do
  @moduledoc false

  @type file_id :: String.t()
  @type query_opts_t :: [
          types: list(String.t())
        ]

  @type file_t :: %{
          id: file_id,
          name: String.t(),
          url: String.t(),
          source: atom()
        }

  @type connection_t :: any()
  @type token_t :: String.t()
  @callback connect(token_t) :: connection_t
  @callback list_files(connection_t, String.t(), query_opts_t) ::
              {:error, :bad_token} | {:error, any()} | {:ok, list(file_t)}
  @callback get_file(connection_t, file_id, (() -> Stream.default())) ::
              {:error, :bad_token} | {:error, any()} | {:ok, list(file_t)}
  @callback refresh_token(oauth_user :: any()) ::
              {:error, :oauth_user_revoked} | {:error, any()} | {:ok, list(file_t)}
end
