module Spec exposing
  ( Outcome
  , Node
  , Step
  , Test
  , get
  , put
  , post
  , delete
  , withEntity
  , Response
  , Request
  , group
  , context
  , describe
  , it
  , test
  , before
  , after
  , http
  , stub, cycle, repeat, stubResult
  , layout
  , stepGroup
  , assert
  , steps
  , run
  , runWithProgram
  , runWithSpi
  , runWithProgramWithSpi

  )

{-| This module provides a way to test Elm apps end-to-end in the browser.

# Types
@docs Test, Node, Step, Request, Response

# Grouping
@docs group, context, describe

# Grouping steps / assertions
@docs stepGroup

# Assertions
@docs Outcome, assert

# Steps
@docs steps

# Defining Tests
@docs it, test

# Hooks
@docs before, after

# Http
@docs http, get, put, post, delete, withEntity

# Stub
@docs stub, repeat, cycle, stubResult

# Layout
@docs layout

# Running
@docs run, runWithProgram, runWithSpi, runWithProgramWithSpi
-}
import Http exposing (Body)
import Spec.Assertions exposing (pass, fail, error)
import Spec.Internal.Runner exposing (Prog, ProgWithSpi, State)
import Spec.Internal.Messages exposing (Msg)
import Spec.Internal.Types exposing (..)
import Spec.Internal.CoreTypes exposing (..)
import Spec.Native

import Task exposing (Task)
import Json.Decode as Json
import Bitwise
import Char
import Dict


{-| Representation of a step.
-}
type alias Step =
  Spec.Internal.Types.Step

{-| Representation of a test.
-}
type alias Test spi msg =
  Spec.Internal.Types.Test spi msg


{-|-}
type alias Response = Spec.Internal.Types.Response
{-|-}
type alias Request = Spec.Internal.Types.Request


{-| The outcome of an assertion or step.
-}
type alias Outcome
  = Spec.Internal.CoreTypes.Outcome


{-| Representation of a test tree (Node).
-}
type alias Node msg =
  Spec.Internal.Types.Node () msg

{-| Representation of a test tree (Node).
-}
type alias NodeWithSpi spi msg =
  Spec.Internal.Types.Node spi msg


flip =
  Spec.Assertions.flip

{-| Groups the given tests and groups into a new group.

    group "description"
      [ it "should do something" []
      , group "sub group"
        [ it "should do something else" []
        ]
      ]
-}
group : String -> List (NodeWithSpi spi msg) -> NodeWithSpi spi msg
group name nodes =
  GroupNode { name = name, nodes = nodes }


{-| Alias for `group`.
-}
context : String -> List (NodeWithSpi spi msg) -> NodeWithSpi spi msg
context =
  group


{-| Alias for `group`.
-}
describe : String -> List (NodeWithSpi spi msg) -> NodeWithSpi spi msg
describe =
  group


{-| Creates a test from the given steps / assertions.

    test "description"
-}
test : String -> List Assertion -> NodeWithSpi spi msg
test name steps =
  TestNode
    { steps = steps
    , requests = []
    , stubs = []
    , results = []
    , layout = []
    , name = name
    , path = []
    , id = -1
    , initCmd = Nothing
    , httpMockInitialised = False
    }


{-| Alias for `it`.
-}
it : String -> List Assertion -> NodeWithSpi spi msg
it =
  test


{-|-}
before : List Assertion -> NodeWithSpi spi msg
before =
  Before

{-|-}
layout : List (String, Rect) -> NodeWithSpi spi msg
layout =
  Layout

{-|-}
after : List Assertion -> NodeWithSpi spi msg
after =
  After


{-|-}
http : List Request -> NodeWithSpi spi msg
http =
  Http


{-|-}
stub : List (spi -> spi) -> NodeWithSpi spi msg
stub =
  Stub


{-|-}
repeat : a -> Cmd a
repeat value =
    stubResult ("repeat: " ++ (toString value)) (always value)

{-|-}
cycle : List a -> Cmd a
cycle values =
    let
        dict : Dict.Dict Int a
        dict = Dict.fromList (List.indexedMap (\i a -> (i, a)) values)

        value : Int -> a
        value invocationCount =
            let
                idx = (((invocationCount - 1) % List.length values))
            in
                case Dict.get idx dict of
                    Just result -> result
                    Nothing -> Debug.crash "No value found"
    in
        stubResult ("cycle: " ++ toString values) value


{-|-}
stubResult: String -> (Int -> a) -> Cmd a
stubResult id fn =
    let
        djb2Hash : Int
        djb2Hash =
          String.foldl (\c h -> (Bitwise.shiftLeftBy h 5) + h + Char.toCode c) 5381 id
    in
        Task.perform fn (Spec.Native.unsafeInvocationCount djb2Hash)


{-| Get sugar
-}
get : String -> Response -> Request
get url response =
    Request "GET" url "" response


{-| Put sugar
-}
put : String -> Response -> Request
put url response =
    Request "PUT" url "" response

{-| Post sugar
-}
post : String -> Response -> Request
post url response =
    Request "POST" url "" response

{-| Delete sugar
-}
delete : String -> Response -> Request
delete url response =
    Request "DELETE" url "" response

{-| set body -}
withEntity : String -> Request -> Request
withEntity entity req =
    { req | entity = entity }

{-| Groups the given steps into a step group. Step groups makes it easy to
run multiple steps under one message.
-}
stepGroup : String -> List Assertion -> Assertion
stepGroup message steps =
  let
    isError outcome =
      case outcome of
        Error _ -> True
        _ -> False

    isFail outcome =
      case outcome of
        Fail _ -> True
        _ -> False

    mapTask task =
      Task.andThen (\_ -> task) Native.Spec.raf

    handleResults results =
      if List.any isError results then
        let
          errorMessage =
            List.filter isError results
              |> List.head
              |> Maybe.map outcomeToString
              |> Maybe.withDefault ""
        in
          Task.succeed (error (message ++ ":\n  " ++ errorMessage))
      else if List.any isFail results then
        let
          failureMessage =
            List.filter isFail results
              |> List.head
              |> Maybe.map outcomeToString
              |> Maybe.withDefault ""
        in
          Task.succeed (fail (message ++ ":\n  " ++ failureMessage))
      else
        Task.succeed (pass message)
  in
    List.map mapTask steps
      |> Task.sequence
      |> Task.andThen handleResults


{-| A record for quickly accessing assertions and giving it a readable format.

    it "should do something"
      [ assert.not.containsText { text = "something", selector = "div" }
      , assert.styleEquals
        { style = "display", value = "block", selector = "div" }
      ]
-}
assert :
  { attributeContains : AttributeData -> Assertion
  , attributeEquals : AttributeData -> Assertion
  , inlineStyleEquals : StyleData -> Assertion
  , valueContains : TextData -> Assertion
  , classPresent : ClassData -> Assertion
  , containsText : TextData -> Assertion
  , styleEquals : StyleData -> Assertion
  , elementPresent : String -> Assertion
  , elementDisabled : String -> Assertion
  , elementVisible : String -> Assertion
  , checkboxChecked : String -> Assertion
  , titleContains : String -> Assertion
  , valueEquals : TextData -> Assertion
  , titleEquals : String -> Assertion
  , urlContains : String -> Assertion
  , urlEquals : String -> Assertion
  , bodyContains : String -> Assertion
  , not :
    { attributeContains : AttributeData -> Assertion
    , attributeEquals : AttributeData -> Assertion
    , inlineStyleEquals : StyleData -> Assertion
    , valueContains : TextData -> Assertion
    , classPresent : ClassData -> Assertion
    , containsText : TextData -> Assertion
    , styleEquals : StyleData -> Assertion
    , elementPresent : String -> Assertion
    , elementDisabled : String -> Assertion
    , checkboxChecked : String -> Assertion
    , elementVisible : String -> Assertion
    , titleContains : String -> Assertion
    , valueEquals : TextData -> Assertion
    , titleEquals : String -> Assertion
    , urlContains : String -> Assertion
    , urlEquals : String -> Assertion
    , bodyContains : String -> Assertion
    }
  }
assert =
  { attributeContains = Spec.Native.attributeContains
  , inlineStyleEquals = Spec.Native.inlineStyleEquals
  , attributeEquals = Spec.Native.attributeEquals
  , elementPresent = Spec.Native.elementPresent
  , elementDisabled = Spec.Native.elementDisabled
  , elementVisible = Spec.Native.elementVisible
  , checkboxChecked = Spec.Native.checkboxChecked
  , valueContains = Spec.Native.valueContains
  , titleContains = Spec.Native.titleContains
  , containsText = Spec.Native.containsText
  , classPresent = Spec.Native.classPresent
  , styleEquals = Spec.Native.styleEquals
  , titleEquals = Spec.Native.titleEquals
  , valueEquals = Spec.Native.valueEquals
  , urlContains = Spec.Native.urlContains
  , urlEquals = Spec.Native.urlEquals
  , bodyContains = Spec.Native.bodyContains
  , not =
    { attributeContains = Spec.Native.attributeContains >> flip
    , inlineStyleEquals = Spec.Native.inlineStyleEquals >> flip
    , attributeEquals = Spec.Native.attributeEquals >> flip
    , elementPresent = Spec.Native.elementPresent >> flip
    , elementDisabled = Spec.Native.elementDisabled >> flip
    , elementVisible = Spec.Native.elementVisible >> flip
    , checkboxChecked = Spec.Native.checkboxChecked >> flip
    , valueContains = Spec.Native.valueContains >> flip
    , titleContains = Spec.Native.titleContains >> flip
    , containsText = Spec.Native.containsText >> flip
    , classPresent = Spec.Native.classPresent >> flip
    , styleEquals = Spec.Native.styleEquals >> flip
    , titleEquals = Spec.Native.titleEquals >> flip
    , valueEquals = Spec.Native.valueEquals >> flip
    , urlContains = Spec.Native.urlContains >> flip
    , urlEquals = Spec.Native.urlEquals >> flip
    , bodyContains = Spec.Native.bodyContains >> flip
    }
  }


{-| Common steps for testing web applications (click, fill, etc..)
-}
steps :
  { dispatchEvent : String -> Json.Value -> String -> Step
  , getAttribute : String -> String -> Task Never String
  , setValue : String -> String -> Step
  , setValueAndDispatch : ValueWithEventData -> Step
  , getTitle : Task Never String
  , clearValue : String -> Step
  , clearValueAndDispatch : EventData -> Step
  , getUrl : Task Never String
  , click : String -> Step
  , inputViaPort : String -> Json.Value -> Step
  , getBody : Task Never String
  , logBody : Step
  }
steps =
  { dispatchEvent = Native.Spec.dispatchEvent
  , getAttribute = Native.Spec.getAttribute
  , clearValue = Native.Spec.clearValue
  , clearValueAndDispatch = Spec.Native.clearValueAndDispatch
  , getTitle = Native.Spec.getTitle
  , setValue = Native.Spec.setValue
  , setValueAndDispatch = Spec.Native.setValueAndDispatch
  , getUrl = Native.Spec.getUrl
  , click = Native.Spec.click
  , inputViaPort = Native.Spec.inputViaPort
  , getBody = Native.Spec.getBody
  , logBody = Native.Spec.logBody
  }


{-| Runs the given tests without an app / component.
-}
run : Node msg -> Program Never (State () String msg) (Msg msg)
run =
  runWithSpi ()


{-| Runs the given tests with the given app / component.
-}
runWithProgram : Prog model msg -> Node msg -> Program Never (State () model msg) (Msg msg)
runWithProgram prog =
  runWithProgramWithSpi { prog | update = always prog.update } ()


{-| Runs the given tests with a & Service Provider Interface but without an app / component
-}
runWithSpi : spi -> NodeWithSpi spi msg -> Program Never (State spi String msg) (Msg msg)
runWithSpi =
  Spec.Internal.Runner.run


{-| Runs the given tests with the given app / component & Service Provider Interface
-}
runWithProgramWithSpi : ProgWithSpi spi model msg -> spi -> NodeWithSpi spi msg -> Program Never (State spi model msg) (Msg msg)
runWithProgramWithSpi =
  Spec.Internal.Runner.runWithProgram
