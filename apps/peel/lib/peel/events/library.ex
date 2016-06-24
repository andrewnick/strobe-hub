defmodule Peel.Events.Library do
  use     GenEvent
  require Logger

  def register do
    Otis.State.Events.add_mon_handler(__MODULE__, [])
  end

  def handle_event({:controller_join, socket}, state) do
    # TODO: icon
    Otis.State.Events.notify({:add_library, %{id: Peel.library_id, title: "Your Music", icon: "", action: "peel:root"}, socket})
    {:ok, state}
  end

  def handle_event({:library_request, channel_id, "peel:" <> route, socket}, state) do
    case route_library_request(channel_id, route) do
      nil ->
        nil
      response ->
        IO.inspect {:peel, :library, response}
        Otis.State.Events.notify({:library_response, "peel", response, socket})
    end
    {:ok, state}
  end


  def handle_event(_event, state) do
    {:ok, state}
  end

  def route_library_request(channel_id, route) when is_binary(route) do
    route_library_request(channel_id, String.split(route, "/", trim: true), route)
  end

  def route_library_request(channel_id, ["track", track_id], _path) do
    {:ok, channel} = Otis.Channels.find(channel_id)
    case Peel.Track.find(track_id) do
      nil ->
        nil
      track ->
        Otis.Channel.append(channel, track)
        nil
    end
  end

  def route_library_request(_channel_id, ["root"], _path) do
    %{
      id: "peel:root",
      title: "Your Music",
      icon: "",
      children: [
        %{ id: "peel:albums", title: "Albums", icon: "", action: "peel:albums" },
        %{ id: "peel:artists", title: "Artists", icon: "", action: "peel:artists" },
        # TODO: other top-level items
      ],
    }
  end

  def route_library_request(_channel_id, ["albums"], path) do
    albums = Peel.Album.all |> Enum.map(fn(album) ->
      %{
        id: "peel:album/#{album.id}",
        title: album.title,
        icon: album.cover_image,
        action: "peel:album/#{album.id}"
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
    case Peel.Album.find(album_id) do
      nil ->
        nil
      album ->
        tracks = album |> Peel.Album.tracks |> Enum.map(fn(track) ->
          %{
            id: "peel:track/#{track.id}",
            title: track.title,
            icon: track.cover_image,
            action: "peel:track/#{track.id}"
          }
        end)
        %{
          id: path,
          title: album.title,
          icon: album.cover_image,
          children: tracks
        }
    end
  end

  def route_library_request(_channel_id, ["artists"], path) do
    artists = Peel.Artist.all |> Enum.map(fn(artist) ->
      %{
        id: "peel:artist/#{artist.id}",
        title: artist.name,
        icon: "",
        action: "peel:artist/#{artist.id}"
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
    case Peel.Artist.find(artist_id) do
      nil ->
        nil
      artist ->
        albums = artist |> Peel.Artist.albums |> Enum.map(fn(album) ->
          %{
            id: "peel:album/#{album.id}",
            title: album.title,
            icon: album.cover_image,
            action: "peel:album/#{album.id}/artist/#{artist_id}"
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
    case Peel.Album.find(album_id) do
      nil ->
        nil
      album ->
        tracks = Peel.Track.album_by_artist(album_id, artist_id)
        children = Enum.map(tracks, fn(track) ->
          %{
            id: "peel:track/#{track.id}",
            title: track.title,
            icon: track.cover_image,
            action: "peel:track/#{track.id}"
          }
        end)
        %{
          id: path,
          title: album.title,
          icon: album.cover_image,
          children: children
        }
    end
  end

  def route_library_request(_channel_id, _route, path) do
    Logger.warn "Invalid path #{path}"
    nil
  end
end
