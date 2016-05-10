module Receiver.View (..) where

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Root
import Receiver
import Channel
import Volume.View


receiverClasses : Receiver.Model -> Bool -> List (String, Bool)
receiverClasses receiver attached =
  [ ( "receiver", True )
  , ( "receiver__offline", not receiver.online )
  , ( "receiver__attached", attached )
  , ( "receiver__detached", not attached )
  ]

attached : Signal.Address Receiver.Action -> Receiver.Model -> Channel.Model -> Html
attached address receiver channel =
  let
    volumeAddress =
      (Signal.forwardTo address Receiver.Volume)
  in
    div
      [ classList (receiverClasses receiver True) ]
      [ div [ class "receiver--state" ] []
      , div [ class "receiver--name" ] [ text receiver.name ]
      , div [ class "receiver--action" ] []
      ]



-- div
--   [ classList
--       [ ( "receiver", True )
--       , ( "receiver--online", receiver.online )
--       , ( "receiver--offline", not receiver.online )
--       ]
--   ]
--   [ Volume.View.control volumeAddress receiver.volume receiver.name ]


detached : Signal.Address Receiver.Action -> Receiver.Model -> Channel.Model -> Html
detached address receiver channel =
  div
    [ classList (receiverClasses receiver False)
    , onClick address (Receiver.Attach channel.id)
    ]
    [ div [ class "receiver--state" ] []
    , div [ class "receiver--name" ] [ text receiver.name ]
    , div [ class "receiver--action receiver--action__attach" ] []
    ]


attach : Signal.Address Receiver.Action -> Channel.Model -> Receiver.Model -> Html
attach address channel receiver =
  div
    [ class "channel-receivers--available-receiver" ]
    [ div
        [ class "channel-receivers--add-receiver"
        , onClick address (Receiver.Attach channel.id)
        ]
        [ text receiver.name ]
    , div
        [ class "channel-receivers--edit-receiver" ]
        [ i [ class "fa fa-pencil" ] [] ]
    ]
