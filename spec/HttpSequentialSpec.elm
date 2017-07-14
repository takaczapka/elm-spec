import Spec exposing (..)

import Html.Attributes exposing (class)
import Html exposing (div, text, span, button)
import Html.Events exposing (onClick)

import Json.Decode as Json

import Http

type alias Model
  = String

type Msg
  = Request
  | Loaded (Result Http.Error String)

init : () -> Model
init _ =
  "Empty"

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    Loaded result ->
      case result of
        Ok data ->
          ( data, Cmd.none )
        Err error ->
          ( "ERROR", Cmd.none )

    Request ->
      ( ""
      , Http.get "/test" Json.string
        |> Http.send Loaded
      )

view : Model -> Html.Html Msg
view model =
  div [ ]
    [ button [ class "get-test", onClick Request ] []
    , span [ ] [ text model ]
    ]

tests =
  describe "Sequential Http Mocking"
    [ http
      [ get "/test" { status = 200, body = "\"OK /first\"" }
      ,  get "/test" { status = 200, body = "\"OK /second\"" }
      ]
    , it "should validate mock http requests sequentially"
      [ assert.containsText { selector = "span", text = "" }
      , steps.click "button.get-test"
      , assert.containsText { selector = "span", text = "OK /first" }
      , steps.click "button.get-test"
      , assert.containsText { selector = "span", text = "OK /second" }
      ]
    ]

main =
  runWithProgram
    { subscriptions = \_ -> Sub.none
    , update = update
    , view = view
    , init = init
    , initCmd = Cmd.none
    } tests
