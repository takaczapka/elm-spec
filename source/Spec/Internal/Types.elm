module Spec.Internal.Types exposing (..)
{-| This internal module contains the types for specs.
@docs Test, Request, Response, Rect, Node, Assertion, Group, Step
@docs AttributeData, ClassData, EventData, StyleData, TextData, ValueData, ValueWithEventData
@docs flatten, outcomeToString
-}
import Task exposing (Task)
import Spec.Internal.CoreTypes exposing (..)
import Spec.Internal.Messages exposing (Msg)

{-| Representation of a test.
-}
type alias Test spi msg =
  { layout : List (String, Rect)
  , requests : List Request
  , stubs: List (spi -> spi)
  , results : List Outcome
  , initCmd : Maybe (Cmd (Msg msg))
  , steps : List Assertion
  , path : List String
  , name : String
  , id : Int
  , httpMockInitialised : Bool
  }


{-| Representation of a mocked request.
-}
type alias Request =
  { method : String
  , url : String
  , entity : String
  , response : Response
  }


{-| Representation of a mocked response.
-}
type alias Response =
  { status : Int
  , body : String
  }

{-| Representation of a rectangle.
-}
type alias Rect =
  { top : Int
  , left : Int
  , bottom : Int
  , right : Int
  , width : Int
  , height : Int
  , zIndex : Int
  }

{-| Representation of a test tree (Node).
-}
type Node spi msg
  = Layout (List (String, Rect))
  | Before (List Assertion)
  | After (List Assertion)
  | Http (List Request)
  | Stub (List (spi -> spi))
  | GroupNode (Group spi msg)
  | TestNode (Test spi msg)


{-| Representation of a test group.
-}
type alias Group spi msg =
  { nodes : List (Node spi msg)
  , name : String
  }


{-| Assertion is just a task that produces an outcome.
-}
type alias Assertion
  = Task Never Outcome


{-| Step is just an alias for assertion.
-}
type alias Step = Assertion


{-| Text data for assertions.
-}
type alias TextData =
  { text : String, selector : String }


{-| Text data for assertions.
-}
type alias ValueData =
  { value : String, selector : String }


{-| Attribute data for assertions.
-}
type alias AttributeData =
  { text : String, selector : String, attribute : String }


{-| Class data for assertions.
-}
type alias ClassData =
  { class : String, selector : String }


{-| Style data for assertions.
-}
type alias StyleData =
  { style : String, value : String, selector : String }

{-| Input event data
-}
type alias ValueWithEventData =
  { value : String, selector : String, eventName : String }


{-| Input event data
-}
type alias EventData =
  { selector : String, eventName : String }

{-| Gets the message from an outcome.
-}
outcomeToString : Outcome -> String
outcomeToString outcome =
  case outcome of
    Error message -> message
    Pass message -> message
    Fail message -> message


{-| Turns a tree into a flat list of tests.
-}
flatten : List (Test spi msg) -> Node spi msg -> List (Test spi msg)
flatten tests node =
  case node of
    -- There branches are processed in the group below
    Before steps ->
      tests

    After steps ->
      tests

    Http mocks ->
      tests

    Stub f ->
      tests

    Layout layout ->
      tests

    {- Process a group node:
       * add before and after hooks to test
       * add requests to tests
    -}
    GroupNode node ->
      let
        getRequests nd =
          case nd of
            Http requests -> requests
            _ -> []

        getStubs nd =
          case nd of
            Stub stubs -> stubs
            _ -> []

        getBefores nd =
          case nd of
            Before steps -> steps
            _ -> []

        getAfters nd =
          case nd of
            After steps -> steps
            _ -> []

        getLayouts nd =
          case nd of
            Layout layouts -> layouts
            _ -> []

        filterNodes nd =
          case nd of
            After _ -> False
            Before _ -> False
            _ -> True

        beforeSteps =
          List.map getBefores node.nodes
            |> List.foldr (++) []

        afterSteps =
          List.map getAfters node.nodes
            |> List.foldr (++) []

        filteredNodes =
          List.filter filterNodes node.nodes

        requests =
          List.map getRequests node.nodes
            |> List.foldr (++) []

        stubs =
          List.map getStubs node.nodes
            |> List.foldr (++) []

        layout =
          List.map getLayouts node.nodes
            |> List.foldr (++) []
      in
        List.map (flatten []) filteredNodes
          |> List.foldr (++) tests
          |> List.map (\test ->
            { test
            | steps = beforeSteps ++ test.steps ++ afterSteps
            , requests = requests ++ test.requests
            , stubs = stubs
            , path = [node.name] ++ test.path
            , layout = test.layout ++ layout
            })

    TestNode node ->
      tests ++ [ node ]
