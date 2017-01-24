defmodule Peel.Events.Library do
  use     GenEvent
  require Logger

  alias Peel.Album
  alias Peel.Artist
  alias Peel.Track

  use  Otis.Library, namespace: "peel"

  def event_handler do
    {__MODULE__, []}
  end

  def setup(state) do
    # Copy my placeholder here
    state
  end

  def library do
    %{ id: Peel.library_id,
      title: "Your Music",
      icon: "",
      actions: %{
        click: %{ url: url("root"), level: true },
        play: nil
      },
      metadata: nil
    }
  end

  def route_library_request(channel_id, ["track", track_id, "play"], _path) do
    Track.find(track_id) |> play(channel_id)
  end
  def route_library_request(channel_id, ["track", track_id], _path) do
    Track.find(track_id) |> play(channel_id)
  end


  def route_library_request(_channel_id, ["root"], _path) do
    %{
      id: "peel:root",
      title: "Your Music",
      icon: "",
      children: [
        %{ id: "peel:albums", title: "Albums", icon: "", actions: %{ click: %{ url: url("albums"), level: true }, play: nil }, metadata: nil },
        %{ id: "peel:artists", title: "Artists", icon: "", actions: %{ click: %{ url: url("artists"), level: true }, play: nil }, metadata: nil },
        # TODO: other top-level items
      ],
    }
  end

  def route_library_request(_channel_id, ["albums"], path) do
    albums = Album.sorted |> Enum.map(fn(album) ->
      %{
        id: "peel:album/#{album.id}",
        title: album.title,
        metadata: node_metadata(album),
        icon: icon(album.cover_image),
        actions: %{
          click: click_action(album),
          play: play_action(album),
        },
      }
    end)
    %{
      id: path,
      title: "Albums",
      icon: "",
      children: albums
    }
  end

  def route_library_request(_channel_id, ["album", album_id], path) do
    case Album.find(album_id) do
      nil ->
        nil
      album ->
        tracks = album |> Album.tracks |> Enum.map(fn(track) ->
          %{
            id: "peel:track/#{track.id}",
            title: track.title,
            icon: icon(track.cover_image),
            actions: %{
              click: click_action(track),
              play: play_action(track)
            },
            metadata: [
              [%{title: Peel.Duration.hms_ms(track.duration_ms), action: nil}],
            ],
          }
        end)
        %{
          id: path,
          title: album.title,
          icon: icon(album.cover_image),
          children: tracks
        }
    end
  end

  def route_library_request(channel_id, ["album", album_id, "play"], _path) do
    case Album.find(album_id) do
      nil ->
        nil
      album ->
        Album.tracks(album) |> play(channel_id)
    end
  end

  def route_library_request(_channel_id, ["artists"], path) do
    artists = Artist.sorted |> Enum.map(fn(artist) ->
      %{
        id: "peel:artist/#{artist.id}",
        title: artist.name,
        icon: "",
        actions: %{ click: click_action(artist), play: nil },
        metadata: nil,
      }
    end)
    %{
      id: path,
      title: "Artists",
      icon: "",
      children: artists
    }
  end

  def route_library_request(_channel_id, ["artist", artist_id], path) do
    case Artist.find(artist_id) do
      nil ->
        nil
      artist ->
        albums = artist |> Artist.albums |> Enum.map(fn(album) ->
          click = click_action(album)
          %{
            id: "peel:album/#{album.id}",
            title: album.title,
            icon: icon(album.cover_image),
            actions: %{
              click: %{ url: "#{click.url}/artist/#{artist_id}", level: true},
              play: %{ url: "#{click.url}/artist/#{artist_id}/play", level: false},
            },
            metadata: album_date_metadata([], album.date)
          }
        end)
        %{
          id: path,
          title: artist.name,
          icon: "",
          children: albums
        }
    end
  end

  def route_library_request(_channel_id, ["album", album_id, "artist", artist_id], path) do
    case Album.find(album_id) do
      nil ->
        nil
      album ->
        tracks = Track.album_by_artist(album_id, artist_id)
        children = Enum.map(tracks, fn(track) ->
          %{
            id: "peel:track/#{track.id}",
            title: track.title,
            icon: icon(track.cover_image),
            actions: %{
              click: click_action(track),
              play: play_action(track)
            },
            metadata: [
              [%{title: Peel.Duration.hms_ms(track.duration_ms), action: nil}],
            ],
          }
        end)
        %{
          id: path,
          title: album.title,
          icon: icon(album.cover_image),
          children: children
        }
    end
  end

  def route_library_request(channel_id, ["album", album_id, "artist", artist_id, "play"], _path) do
    case Album.find(album_id) do
      nil ->
        nil
      _album ->
        tracks = Track.album_by_artist(album_id, artist_id)
        play(tracks, channel_id)
    end
  end

  def route_library_request(_channel_id, _route, path) do
    Logger.warn "Invalid path #{path}"
    nil
  end

  def node_metadata(%Album{} = album) do
    album_metadata(album, Album.artists(album))
  end

  def album_metadata(_album, nil) do
  end
  def album_metadata(album, [artist]) do
    [ [link(artist)] ] |> album_date_metadata(album.date)
  end
  def album_metadata(album, _artists) do
    [ [link("Various Artists", nil)] ] |> album_date_metadata(album.date)
  end

  def album_date_metadata([], nil) do
    nil
  end
  def album_date_metadata(metadata, nil) do
    metadata
  end
  def album_date_metadata(metadata, date) do
    # TODO: add action for searching by date
    metadata ++ [[ library_link(date, nil) ]]
  end

  def link(%Track{title: title} = track) do
    library_link title, click_action(track)
  end
  def link(%Album{title: title} = album) do
    library_link title, click_action(album)
  end
  def link(%Artist{name: name} = artist) do
    library_link name, click_action(artist)
  end
  def link(_) do
    library_link("", nil)
  end

  def link(title, action) when is_binary(title) do
    library_link(title, action)
  end

  def click_action(%Track{id: id}) do
    %{ url: url(["track", id, "play"]), level: false }
  end

  def click_action(%Album{id: id}) do
    %{ url: url(["album", id]), level: true }
  end

  def click_action(%Artist{id: id}) do
    %{ url: url(["artist", id]), level: true }
  end

  def play_action(%Track{id: id}) do
    %{ url: url(["track", id, "play"]), level: false }
  end

  def play_action(%Album{id: id}) do
    %{ url: url(["album", id, "play"]), level: false }
  end

  def play_action(%Artist{id: id}) do
    %{ url: url(["artist", id, "play"]), level: false }
  end

  def icon(nil), do: ""
  def icon(icon), do: icon
end