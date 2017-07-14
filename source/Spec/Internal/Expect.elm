module Spec.Internal.Expect exposing (..)
{-| This is an internal module.
Feel free to use, but it's more unstable than 'public' modules.
@docs equals
-}

import Spec.Assertions exposing (fail, pass)
import Spec.Internal.Types exposing (..)
import Task exposing (Task)

{-| equals
-}
equals : a -> String -> Task Never a -> Assertion
equals expected message  =
  Task.map (\actual ->
    if actual == expected then
      pass message
    else
      fail (message ++ "\n" ++ (toString actual) ++ " <=> " ++ (toString expected))
  )
