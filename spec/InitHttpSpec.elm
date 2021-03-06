import Spec exposing (..)
import Spec.Expect as Expect

import Html.Events exposing (onClick, on, keyCode)
import Html.Attributes exposing (class, attribute)
import Html exposing (..)

import Http

import Json.Encode as JE
import Json.Decode as JD

import Task exposing (Task)

type alias Model = String

type Msg
  = Request
  | Loaded (Result Http.Error String)


init : () -> Model
init _ =
  ""

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    Request ->
      ( model, load )

    Loaded (Err e) ->
      ( model, Cmd.none )

    Loaded (Ok result) ->
      ( result, Cmd.none )


load : Cmd Msg
load =
    Http.get "/test" JD.string |> Http.send Loaded


view : Model -> Html.Html Msg
view model =
  node "test" []
    [ div [ class "value"] [ text model ]
   ]


specs : Node msg
specs =
  describe "Spec.Steps"
    [ http
       [ { method = "GET"
         , url = "/test"
         , response = { status = 200, body = "\"new-value\"" }
         }
       ]
    , describe ".setValue"
      [ it "should set value of element on init"
        [ assert.containsText { text = "new-value", selector = ".value" }
        ]
      ]
    ]

main =
  runWithProgram
    { init = init
    , initCmd = load
    , update = update
    , view = view
    , subscriptions = \_ -> Sub.none
    } specs
