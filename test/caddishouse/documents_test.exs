defmodule Caddishouse.DocumentsTest do
  use Caddishouse.DataCase

  alias Caddishouse.Documents
  import Mox

  setup :verify_on_exit!

  setup do
    user = insert(:user)
    oauth_user = insert(:oauth_user, user: user)

    media =
      string_params_for(:media, user_id: user.id, oauth_user_id: oauth_user.id)
      |> Map.put("file", %Plug.Upload{
        content_type: "application/pdf",
        filename: "some-type-file.pdf",
        path: "./test/support/pdfs/sample.pdf"
      })

    {:ok, media} = Documents.find_or_create(media)

    %{user: user, oauth_user: oauth_user, media: media}
  end

  describe "Documents" do
    test "finds media, otherwise creates it", %{user: user, oauth_user: oauth_user} do
      media =
        string_params_for(:media, user_id: user.id, oauth_user_id: oauth_user.id)
        |> Map.put("file", %Plug.Upload{
          content_type: "application/pdf",
          filename: "some-random-type-file.pdf",
          path: "./test/support/pdfs/sample.pdf"
        })

      {:ok, first_media} = Documents.find_or_create(media)
      {:ok, second_media} = Documents.find_or_create(media)

      # Ensure that the media file is created only once and the "cached" version
      # is returned
      assert first_media.id == second_media.id

      # Media file fails
      media =
        string_params_for(:media, user_id: user.id, oauth_user_id: oauth_user.id)
        |> Map.put("file", %Plug.Upload{
          content_type: "application/pdf",
          filename: "some-file-doesnt-exist.pdf",
          path: "./test/support/pdfs/some-file-doesnt-exist.pdf"
        })

      {:error, changeset} = Documents.find_or_create(media)
      assert %{file: ["is invalid"]} == errors_on(changeset)
    end

    test "metadata considered loaded only when load_metadata/2 is called", %{media: media} do
      assert Documents.metadata_loaded?(media) == false

      metadata = string_params_for(:metadata)
      {:ok, media} = Documents.load_metadata(media, metadata)
      assert Documents.metadata_loaded?(media)
    end

    test "starts background job when importing media", %{user: user, oauth_user: oauth_user} do
      media = params_for(:media)

      job_attrs = %{
        user_id: user.id,
        oauth_user_id: oauth_user.id,
        source_key: media.source_key,
        file_name: "some-random-file-name"
      }

      Oban.Testing.with_testing_mode(:manual, fn ->
        Documents.import_media(user, oauth_user, media.source_key, job_attrs.file_name)
        assert_enqueued(worker: Caddishouse.Documents.Jobs.ImportMedia, args: job_attrs)

        # Only queues up once
        Documents.import_media(user, oauth_user, media.source_key, job_attrs.file_name)
        assert Enum.count(all_enqueued(worker: Caddishouse.Documents.Jobs.ImportMedia)) == 1
      end)
    end

    test "background job downloads and saves media file", %{user: user, oauth_user: oauth_user} do
      media = params_for(:media)
      file_name = "some-background-job-file-name"

      Caddishouse.GoogleMock
      |> expect(:connect, fn _ -> %{} end)
      |> expect(:get_file, fn _, _, _ -> {:ok, "./test/support/pdfs/sample.pdf"} end)

      job_attrs = %{
        user_id: user.id,
        oauth_user_id: oauth_user.id,
        source_key: media.source_key,
        file_name: file_name
      }

      assert Enum.count(Documents.search(user, file_name)) == 0

      {:ok, :processing_media} =
        Documents.import_media(user, oauth_user, media.source_key, job_attrs.file_name)

      assert Enum.count(Documents.search(user, file_name)) == 1
      # Does not import when media exists
      {:ok, %Documents.Media{id: _}} =
        Documents.import_media(user, oauth_user, media.source_key, job_attrs.file_name)
    end

    test "retrieving media by id updates last viewed", %{media: media, user: user} do
      assert is_nil(media.last_viewed_at)
      updated_media = Documents.get_by_id!(user, media.id)
      assert !is_nil(updated_media.last_viewed_at)
    end

    test "recently viewed returns most recently fetched", %{
      media: _media,
      user: user,
      oauth_user: oauth_user
    } do
      now = Timex.now()

      media1 =
        insert(:media,
          user_id: user.id,
          oauth_user_id: oauth_user.id,
          last_viewed_at: Timex.shift(now, minutes: -1)
        )

      media2 =
        insert(:media,
          user_id: user.id,
          oauth_user_id: oauth_user.id,
          last_viewed_at: Timex.shift(now, minutes: -3)
        )

      media3 =
        insert(:media,
          user_id: user.id,
          oauth_user_id: oauth_user.id,
          last_viewed_at: Timex.shift(now, minutes: -2)
        )

      insert(:media, user_id: user.id, oauth_user_id: oauth_user.id, last_viewed_at: nil)

      assert [media1.id, media3.id, media2.id] ==
               Enum.map(Documents.recently_viewed(user, 3), & &1.id)
    end

    test "search returns results"

    test "update current page updates current page in metadata"

    test "deletes document", %{user: user, media: media} do
      assert media.id == Documents.get_by_id!(user, media.id).id

      Caddishouse.StorageMock
      |> expect(:delete, fn _, _ -> {:ok, media} end)

      Documents.delete_media(user, media)

      # TODO add check that row continues to exist if storage api was unable to delete file

      assert_raise Ecto.NoResultsError, fn ->
        Documents.get_by_id!(user, media.id)
      end
    end
  end
end
