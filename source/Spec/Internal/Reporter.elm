module Spec.Internal.Reporter exposing (render)
{-| Renders test results in Html.

@docs render
-}
import Spec.Internal.Styles as Styles
import Spec.Internal.Types exposing (..)
import Spec.Internal.CoreTypes exposing (Outcome)
import Spec.Internal.CoreTypes exposing (Outcome(..))

import Json.Encode

import Html.Attributes exposing (style, property)
import Html exposing (div, strong, text)


{-| Renders an outcome.
-}
renderOutcome : Outcome -> Html.Html msg
renderOutcome outcome =
  let
    html =
      outcome
        |> outcomeToString
        |> Native.Spec.ansiToHtml
        |> Json.Encode.string

    styles =
      case outcome of
        Pass _ ->
          style [ ( "color", "green" ) ]

        Error _ ->
          style
            [ ( "color", "white" )
            , ( "background-color", "red" )
            ]

        Fail _ ->
          style [ ( "color", "red" ) ]
  in
    div
      [ property "innerHTML" html
      , styles
      ]
      []


{-| Renders a test.
-}
renderTest : Test spi msg -> Html.Html msg
renderTest model =
  let
    requests =
      Native.Spec.getMockResults model

    notCalled =
      List.filter
        (\item -> not (List.member item requests.called))
        model.requests

    title =
      [ strong [] [ text model.name ] ]

    results =
      List.map renderOutcome model.results

    renderRequest class request =
      div
        [ ]
        [ text (request.method ++ " - " ++ request.url ++ " - " ++ request.entity) ]

    requestResults =
      if List.isEmpty requests.called
      && List.isEmpty requests.unhandled
      && List.isEmpty notCalled
      then
        []
      else
        [ div [ ] [ text "Requets:" ]]
        ++ (List.map (renderRequest Styles.CalledRequest) requests.called)
        ++ (List.map (renderRequest Styles.NotCalledRequest) notCalled)
        ++ (List.map (renderRequest Styles.UnhandledRequest) requests.unhandled)

  in
    div
      [ ] (title ++ results ++ requestResults)


{-| Renders the test results.
-}
render : List (Test spi msg) -> Html.Html msg
render tests =
  let
    styles =
      [ ]

    rows =
      List.map renderTest tests
  in
    Html.div [ ] (styles ++ rows)
