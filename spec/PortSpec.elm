module Main exposing (..)

import Spec exposing (..)
import Spec.Internal.Expect as Expect
import Html.Events exposing (onClick, on, keyCode)
import Html.Attributes exposing (class, attribute)
import Html exposing (..)
import Json.Encode as JE
import Json.Decode as JD
import Ports
import Array exposing (Array)

type alias Model =
  String


type Msg
  = SetValue String


init : () -> Model
init _ =
  ""


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    SetValue value ->
      ( value, Cmd.none )


view : Model -> Html.Html Msg
view model =
  node "test"
    []
    [ div [ class "value" ] [ text model ]
    ]


specs : Node msg
specs =
  describe "Spec.Steps"
    [ describe ".setValue"
      [ it "should set value of element on init"
        [ assert.containsText { text = "", selector = ".value" }
        , steps.inputViaPort "inputValue" (JE.string "new-value-from-port")
        , assert.containsText { text = "new-value-from-port", selector = ".value" }
        ]
      ]
    ]


main =
  runWithProgram
    { init = init
    , update = update
    , view = view
    , subscriptions = \_ -> Sub.batch [ Ports.inputValue SetValue ]
    , initCmd = Cmd.none
    }
    specs
