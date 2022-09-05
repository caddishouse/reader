defmodule Caddishouse.Tests.Factory do
  # with Ecto
  use ExMachina.Ecto, repo: Caddishouse.Repo

  def user_factory do
    %Caddishouse.Accounts.User{}
  end

  def oauth_user_factory do
    %Caddishouse.Accounts.OAuthUser{
      email: sequence(:email, &"email-#{&1}@example.com"),
      access_token: sequence(:access_token, &"some-access-token#{&1}"),
      refresh_token: sequence(:refresh_token, &"some-refresh-token-#{&1}"),
      external_id: sequence(:external_id, &"some-external-id-#{&1}"),
      provider: :google,
      user: build(:user)
    }
  end

  def media_factory do
    %Caddishouse.Documents.Media{
      name: sequence(:name, &"some-name-#{&1}"),
      file_size: 10000,
      source_key: sequence(:source_key, &"some-id-#{&1}"),
      mimetype: "applcation/pdf",
      metadata: build(:metadata)
    }
  end

  def metadata_factory do
    %Caddishouse.Documents.Media.Metadata{}
  end
end
