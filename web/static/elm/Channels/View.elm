module Channels.View (channels, player, playlist) where

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Debug
import Json.Decode as Json
import Root
import Root.State
import Channels
import Channels.State
import Receivers
import Receivers.State
import Channel
import Channel.View
import Volume.View
import Library.View
import Input
import Input.View
import Source.View


channels : Signal.Address Channels.Action -> Channels.Model -> Receivers.Model -> Html
channels address channels receivers =
  case Channels.State.activeChannel channels of
    Nothing ->
      div [] []

    Just activeChannel ->
      channelsBar address channels receivers activeChannel


channelsBar : Signal.Address Channels.Action -> Channels.Model -> Receivers.Model -> Channel.Model -> Html
channelsBar address channels receivers activeChannel =
  let
    channelAddress =
      Signal.forwardTo address (Channels.Modify activeChannel.id)

    volumeAddress =
      Signal.forwardTo channelAddress Channel.Volume
  in
    div
      [ classList [ ( "channels", True ), ( "channels__select-channel", channels.showChannelSwitcher ) ] ]
      [ div
          [ class "channels--bar" ]
          [ div
              [ class "channels--channel-select", onClick address (Channels.ToggleSelector) ]
              [ i [ class "fa fa-bullseye" ] [] ]
          , div
              [ class "channels--channel-volume" ]
              [ (Volume.View.control volumeAddress activeChannel.volume activeChannel.name) ]
          ]
      , (channelSelectorPanel address channels receivers activeChannel)
      ]


channelSelectorPanel : Signal.Address Channels.Action -> Channels.Model -> Receivers.Model -> Channel.Model -> Html
channelSelectorPanel address channels receivers activeChannel =
  let
    -- unselectedChannels =
    --   List.filter (\channel -> channel.id /= activeChannel.id) channels.channels
    orderedChannels =
      List.sortBy (\c -> c.originalName) channels.channels
  in
    case channels.showChannelSwitcher of
      False ->
        div [] []

      True ->
        div
          [ class "channels-selector" ]
          [ div
              [ class "channels-selector--list" ]
              (List.map (channelChoice address receivers activeChannel) orderedChannels)
          , addChannelPanel address channels
          ]


channelChoice : Signal.Address Channels.Action -> Receivers.Model -> Channel.Model -> Channel.Model -> Html
channelChoice address receivers activeChannel channel =
  let
    attachedReceivers =
      (Receivers.State.attachedReceivers receivers channel) |> List.length

    duration =
      case (Channel.playlistDuration channel) of
        Nothing ->
          ""

        Just 0 ->
          ""

        time ->
          Source.View.durationString time

    onClickChoose =
      onClick address (Channels.Choose channel)

    channelAddress =
      Signal.forwardTo address (Channels.Modify channel.id)

    editNameInput =
      case channel.editName of
        False ->
          div [] []

        True ->
          let
            context =
              { address = Signal.forwardTo channelAddress Channel.EditName
              , cancelAddress = Signal.forwardTo channelAddress (always (Channel.ShowEditName False))
              , submitAddress = Signal.forwardTo channelAddress Channel.Rename
              }
          in
            Input.View.inputSubmitCancel context channel.editNameInput
  in
    div
      [ classList
          [ ( "channels-selector--channel", True )
          , ( "channels-selector--channel__active", channel.id == activeChannel.id )
          , ( "channels-selector--channel__playing", channel.playing )
          , ( "channels-selector--channel__edit", channel.editName )
          ]
      ]
      [ div
          [ classList
              [ ( "channels-selector--display", True )
              , ( "channels-selector--display__inactive", channel.editName )
              ]
          ]
          [ div [ class "channels-selector--channel--name", onClickChoose ] [ text channel.name ]
          , div [ class "channels-selector--channel--duration duration", onClickChoose ] [ text duration ]
          , div
              [ classList
                  [ ( "channels-selector--channel--receivers", True )
                  , ( "channels-selector--channel--receivers__empty", attachedReceivers == 0 )
                  ]
              , onClickChoose
              ]
              [ text (toString attachedReceivers) ]
          , div [ class "channels-selector--channel--edit", onClick address (Channels.Modify channel.id (Channel.ShowEditName True)) ] []
          ]
      , div
          [ classList
              [ ( "channels-selector--edit", True )
              , ( "channels-selector--edit__active", channel.editName )
              ]
          ]
          [ editNameInput ]
      ]


addChannelPanel : Signal.Address Channels.Action -> Channels.Model -> Html
addChannelPanel address model =
  let
    context =
      { address = Signal.forwardTo address Channels.NewInput
      , cancelAddress = Signal.forwardTo address (always Channels.ToggleAdd)
      , submitAddress = Signal.forwardTo address Channels.Add
      }
  in
    case model.showAddChannel of
      False ->
        div
          [ class "channel-selector--add", onClick address (Channels.ToggleAdd) ]
          [ text "Add new channel..." ]

      True ->
        Input.View.inputSubmitCancel context model.newChannelInput


player : Signal.Address Channels.Action -> Channel.Model -> Html
player address channel =
  let
    playerAddress =
      Signal.forwardTo address (Channels.Modify channel.id)
  in
    Channel.View.root playerAddress channel


playlist : Signal.Address Channels.Action -> Channels.Model -> Html
playlist address model =
  let
    playlist =
      case Channels.State.activeChannel model of
        Nothing ->
          div [] []

        Just channel ->
          Channel.View.playlist (Signal.forwardTo address (Channels.Modify channel.id)) channel
  in
    playlist
