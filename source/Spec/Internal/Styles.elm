module Spec.Internal.Styles exposing (..)

{-| Styles for the Html reporter.

@docs Class
-}
import Html


{-| Classes for the styles.
-}
type Class
  = NotCalledRequest
  | UnhandledRequest
  | CalledRequest
  | Container
  | SubTitle
  | Test
  | Row
