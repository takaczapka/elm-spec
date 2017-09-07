module Main exposing (..)

import Spec exposing (..)
import Html.Attributes exposing (class)
import Html exposing (div, text, span, button)
import Html.Events exposing (onClick)
import Json.Decode as Decode exposing (Decoder, field, succeed, string, int, bool, list, andThen, maybe, map)

import Json.Encode as Encode
import Http


type alias Model =
    Maybe Fruit


type alias Fruit =
    { name : String
    , taste : String
    }


type Msg
    = RequestAFruit
    | FruitLoaded (Result Http.Error Fruit)


init : () -> Model
init _ =
    Nothing


decodeFruit : Decode.Decoder Fruit
decodeFruit =
    Decode.map2 Fruit
        (field "name" string)
        (field "taste" string)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FruitLoaded (Ok fruit) ->
            ( Just fruit, Cmd.none )

        FruitLoaded (Err error) ->
            let
                _ =
                    Debug.log "Error loading a fruit" error
            in
                ( model, Cmd.none )

        RequestAFruit ->
            ( model
            , Http.get "/fruit" decodeFruit
                |> Http.send FruitLoaded
            )


view : Model -> Html.Html Msg
view model =
    div []
        ([ button [ class "get-a-fruit", onClick RequestAFruit ] [] ]
            ++ (case model of
                    Just fruit ->
                        [ span [ class "name" ] [ text fruit.name ]
                        , span [ class "taste" ] [ text fruit.taste ]
                        ]

                    Nothing ->
                        []
               )
        )


tests =
    describe "Http Mocking"
        [ http
            [ get "/fruit" { status = 200, body = "{\"name\" : \"banana\", \"taste\":\"not bad\"}" }
            , get "/fruit" { status = 200, body = "{\"name\" : \"cherry\", \"taste\":\"superb\"}" }
            , get "/fruit" { status = 200, body = encodeMango }
            ]
        , it "should mock http requests"
            [ assert.not.elementPresent ".name"
            , steps.click "button.get-a-fruit"
            , assert.containsText { selector = ".name", text = "banana" }
            , assert.containsText { selector = ".taste", text = "not bad" }
            , steps.click "button.get-a-fruit"
            , assert.containsText { selector = ".name", text = "cherry" }
            , assert.containsText { selector = ".taste", text = "superb" }
            , steps.click "button.get-a-fruit"
            , assert.containsText { selector = ".name", text = "mango" }
            , assert.containsText { selector = ".taste", text = "oh my god" }
            ]
        ]


encodeMango : String
encodeMango =
    Encode.encode 0 (Encode.object [ ("name", Encode.string "mango"), ("taste", Encode.string "oh my god") ])


main =
    runWithProgram
        { subscriptions = \_ -> Sub.none
        , update = update
        , view = view
        , init = init
        , initCmd = Cmd.none
        }
        tests
