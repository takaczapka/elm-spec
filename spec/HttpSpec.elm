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
  | RequestPost
  | RequestPostWithBody String
  | RequestPutWithBody String
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

    RequestPost ->
      ( ""
      , Http.post "/blah" Http.emptyBody Json.string
        |> Http.send Loaded
      )

    RequestPostWithBody body ->
      ( ""
      , Http.post "/test-post-with-body" (Http.stringBody "text/plain" body) Json.string
        |> Http.send Loaded
      )

    RequestPutWithBody body ->
      let
        put = Http.request
                { method = "PUT"
                , headers = []
                , url = "/test-put-with-body"
                , body = (Http.stringBody "text/plain" body)
                , expect = Http.expectJson Json.string
                , timeout = Nothing
                , withCredentials = False
                }
      in
      ( ""
      , Http.send Loaded put
      )

    Request ->
      ( ""
      , Http.get "/test" Json.string
        |> Http.send Loaded
      )

view : Model -> Html.Html Msg
view model =
  div [ ]
    [ button [ class "get-test", onClick Request ] []
    , button [ class "post-blah", onClick RequestPost ] []
    , button [ class "post-with-body", onClick (RequestPostWithBody "post-body") ] []
    , button [ class "put-with-body", onClick (RequestPutWithBody "put-body") ] []
    , span [ ] [ text model ]
    ]

tests =
  describe "Http Mocking"
    [ http
      [ get "/test" { status = 200, body = "\"OK /test\"" }
      , post "/blah" { status = 500, body = "" }
      , post "/test-post-with-body" { status = 200, body = "\"OK post done\"" } |> withEntity "post-body"
      , put "/test-put-with-body" { status = 200, body = "\"OK put done\"" } |> withEntity "put-body"
      ]
    , it "should mock http requests"
      [ assert.containsText { selector = "span", text = "" }
      , steps.click "button.get-test"
      , assert.containsText { selector = "span", text = "OK /test" }
      , steps.click "button.post-blah"
      , assert.containsText { selector = "span", text = "ERROR" }
      , steps.click "button.post-with-body"
      , assert.containsText { selector = "span", text = "OK post done" }
      , steps.click "button.put-with-body"
      , assert.containsText { selector = "span", text = "OK put done" }
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
