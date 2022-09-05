defmodule Caddishouse.Documents.Media.Metadata do
  use Ecto.Schema
  import Ecto.Changeset

  @metadata_version 1

  embedded_schema do
    field :version, :integer, default: 0
    field :current_page, :integer, default: 1
    field :total_pages, :integer, default: 1

    embeds_many :parts, Parts do
      field :page, :integer
      field :dest, {:array, :map}
      field :title, :string
      field :level, :integer
    end
  end

  def metadata_version(), do: @metadata_version

  @doc """
  On initial import, we load default metadata as defined in the schema.
  This shouldn't be used outside of `Caddishouse.Documents.Media`

  On first load of the PDF, we then update the metadata with actual
  information using the update changeset.
  """
  def build_defaults(%__MODULE__{} = metadata, attrs) do
    metadata
    |> cast(attrs, [:current_page, :total_pages])
  end

  defp build_parts(parts, attrs) do
    parts
    |> cast(attrs, [:page, :title, :level])
    |> update_change(:title, &sanitize_title/1)
  end

  def build(%__MODULE__{} = metadata, attrs) do
    metadata
    |> cast(attrs, [:current_page, :total_pages])
    |> put_change(:version, @metadata_version)
    |> cast_embed(:parts, with: &build_parts/2)
  end

  def update_current_page(%__MODULE__{} = metadata, current_page) do
    metadata
    |> cast(%{"current_page" => current_page}, [:current_page])
  end

  # Embedded schemas do not sanitize
  defp sanitize_title(title), do: String.replace(title, "\u0000", "")
end

defmodule Caddishouse.Documents.Media do
  @moduledoc false
  use Ecto.Schema
  use Waffle.Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "media" do
    field :name, :string
    # ID of file as it exists in cloud storage
    field :source_key, :string
    field :last_viewed_at, :utc_datetime
    field :file_size, :integer
    field :mimetype, :string
    # TODO add some type of oauth identification here so that
    # when a user disconnects their oauth they can delete their files
    # here...
    field :file, CaddishouseWeb.Uploaders.Media.Type

    embeds_one :metadata, Caddishouse.Documents.Media.Metadata
    belongs_to :oauth_user, Caddishouse.Accounts.OAuthUser
    belongs_to :user, Caddishouse.Accounts.User

    timestamps()
  end

  @doc """
  Media.file requires
    %Plug.Upload{
      filename: media.name,
      path: /tmp/path_to_file
    }
  """
  def build(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:user_id, :oauth_user_id, :source_key, :name, :file_size, :mimetype])
    |> validate_required([:name, :user_id, :oauth_user_id, :source_key, :file_size, :mimetype])
    |> unique_constraint([:source_key, :oauth_user_id])
    |> build_metadata_defaults()
  end

  defp build_metadata_defaults(media) do
    cast(media, %{"metadata" => %{}}, [])
    |> cast_embed(:metadata,
      required: true,
      with: &Caddishouse.Documents.Media.Metadata.build_defaults/2
    )
  end

  # TODO can replace this with update_metadata instead...
  def build_metadata(media, attrs) do
    cast(media, %{"metadata" => Map.put(attrs, "id", media.metadata.id)}, [])
    |> cast_embed(:metadata, required: true, with: &Caddishouse.Documents.Media.Metadata.build/2)
  end

  defp update_metadata(media, changes) do
    change(media)
    |> put_change(:metadata, changes)
  end

  def current_page(media, current_page) do
    update_metadata(
      media,
      Caddishouse.Documents.Media.Metadata.update_current_page(media.metadata, current_page)
    )
  end

  def add_file(%__MODULE__{} = media, attrs) do
    media
    |> cast_attachments(attrs, [:file])
    |> validate_required([:file])
  end

  def last_viewed(media) do
    now = Timex.now() |> DateTime.truncate(:second)
    change(media, last_viewed_at: now)
  end
end
