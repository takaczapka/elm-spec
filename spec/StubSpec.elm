module Main exposing (..)

import Spec exposing (..)
import Html.Attributes exposing (class)
import Html exposing (div, text, span, button)
import Html.Events exposing (onClick)
import Json.Decode as Json
import Http
import Task
import Dict


type alias Model =
    String


type Msg
    = Request
    | RequestPost
    | RequestPostWithBody String
    | RequestPutWithBody String
    | Loaded (Result Http.Error String)


init : () -> Model
init _ =
    "Empty"


type alias Spi =
    { request : Cmd Msg
    , requestPost : Cmd Msg
    , requestPostWithBody : String -> Cmd Msg
    , requestPutWithBody : String -> Cmd Msg
    }


stubSpi : Spi
stubSpi =
    { request = Cmd.none
    , requestPost = Cmd.none
    , requestPostWithBody = always Cmd.none
    , requestPutWithBody = always Cmd.none
    }


realSpi : Spi
realSpi =
    { request =
        Http.get "/test" Json.string
            |> Http.send Loaded
    , requestPost = Http.post "/blah" Http.emptyBody Json.string |> Http.send Loaded
    , requestPostWithBody =
        \body ->
            Http.post "/test-post-with-body" (Http.stringBody "text/plain" body) Json.string
                |> Http.send Loaded
    , requestPutWithBody =
        \body ->
            Http.send Loaded
                (Http.request
                    { method = "PUT"
                    , headers = []
                    , url = "/test-put-with-body"
                    , body = (Http.stringBody "text/plain" body)
                    , expect = Http.expectJson Json.string
                    , timeout = Nothing
                    , withCredentials = False
                    }
                )
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update = testableUpdate realSpi

testableUpdate : Spi -> Msg -> Model -> ( Model, Cmd Msg )
testableUpdate spi msg model =
    case msg of
        Loaded result ->
            case result of
                Ok data ->
                    ( data, Cmd.none )

                Err error ->
                    ( "ERROR", Cmd.none )

        RequestPost ->
            ( ""
            , spi.requestPost
            )

        RequestPostWithBody body ->
            ( ""
            , spi.requestPostWithBody body
            )

        RequestPutWithBody body ->
            ( ""
            , spi.requestPutWithBody body
            )

        Request ->
            ( ""
            , spi.request
            )


view : Model -> Html.Html Msg
view model =
    div []
        [ button [ class "get-test", onClick Request ] []
        , button [ class "post-blah", onClick RequestPost ] []
        , button [ class "post-with-body", onClick (RequestPostWithBody "post-body") ] []
        , button [ class "put-with-body", onClick (RequestPutWithBody "put-body") ] []
        , span [] [ text model ]
        ]


loadedOk : Cmd String -> Cmd Msg
loadedOk =
    Cmd.map (Ok >> Loaded)


tests =
    describe "Stubbing"
        [ stub
            [ \spi -> { spi | request             = loadedOk <| cycle ["OK /test", "ERROR"]    }
            , \spi -> { spi | requestPost         = loadedOk <| repeat "ERROR"                 }
            , \spi -> { spi | requestPostWithBody = \body -> loadedOk <| repeat "OK post done" }
            , \spi -> { spi | requestPutWithBody  = \body -> loadedOk <| repeat "OK put done"  }
            ]
        , it "should intercept calls to the service provider interface"
            [ assert.containsText { selector = "span", text = "" }
            , steps.click "button.get-test"
            , assert.containsText { selector = "span", text = "OK /test" }
            , steps.click "button.get-test"
            , assert.containsText { selector = "span", text = "ERROR" }
            , steps.click "button.post-blah"
            , assert.containsText { selector = "span", text = "ERROR" }
            , steps.click "button.post-with-body"
            , assert.containsText { selector = "span", text = "OK post done" }
            , steps.click "button.put-with-body"
            , assert.containsText { selector = "span", text = "OK put done" }
            ]
        ]


main =
    runWithProgramWithSpi
        { subscriptions = \_ -> Sub.none
        , update = testableUpdate
        , view = view
        , init = init
        , initCmd = Cmd.none
        }
        stubSpi
        tests
