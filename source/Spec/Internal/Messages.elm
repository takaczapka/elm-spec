module Spec.Internal.Messages exposing (..)
{-|Internal module
@docs Msg
-}

import Spec.Internal.CoreTypes exposing (..)

{-| Messages for a test program.
-}
type Msg msg
  = Next (Maybe Outcome)
  | NoOp ()
  | App msg
