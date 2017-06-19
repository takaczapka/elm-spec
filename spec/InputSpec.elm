import Spec exposing (..)
import Spec.Expect as Expect

import Html.Events exposing (onClick, on, keyCode, onInput)
import Html.Attributes exposing (..)
import Html exposing (..)

import Json.Encode as JE
import Json.Decode as JD

type alias Model = String

type Msg
  = SetValue String
  | Set


init : () -> Model
init _ =
  "Empty"


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    SetValue value ->
      ( value, Cmd.none )

    Set ->
      ( "Something", Cmd.none )


view : Model -> Html.Html Msg
view model =
  node "test" []
    [ div
      [ attribute "test" "test", onClick Set ] [ text "set-me" ]
    , input [class "my-input", value model, onInput SetValue] []
    ]


specs : Node msg
specs =
  describe "Spec.Steps"
    [ before [ assert.elementPresent "body" ]
    , after [ assert.elementPresent "body" ]
    , describe ".setValue"
      [ it "should set value of element"
        [ assert.valueEquals { text = "Empty", selector = ".my-input" }
        , steps.setValueAndDispatch { value = "a mew value", selector = ".my-input", eventName = "input" }
        , assert.valueEquals { text = "a mew value", selector = ".my-input" }
        ]
      ]
    , describe ".clearValueAndDispatch"
      [ it "should clear value of element" [
         assert.valueEquals { text = "Empty", selector = ".my-input" }
        , steps.clearValueAndDispatch { selector = ".my-input", eventName = "input" }
        , assert.valueEquals { text = "", selector = ".my-input" }
        ]
      ]
    ]

main =
  runWithProgram
    { init = init
    , initCmd = Cmd.none
    , update = update
    , view = view
    , subscriptions = \_ -> Sub.none
    } specs
