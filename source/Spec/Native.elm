module Spec.Native exposing (..)
{-| Functions for native modules containing assertions.

# Assertions
@docs containsText, attributeContains, attributeEquals, classPresent
@docs styleEquals, elementPresent, elementVisible, titleContains
@docs titleEquals, urlContains, urlEquals, valueContains, valueEquals
@docs clearValueAndDispatch
@docs bodyContains, checkboxChecked, elementDisabled, inlineStyleEquals
@docs setValueAndDispatch
@docs unsafeInvocationCount

# Steps
@docs clearValueAndDispatch
-}
import Spec.Internal.Types exposing (..)
import Task exposing (Task)
import Native.HttpMock
import Native.Spec


{-| Checks if the given element contains the specified text.
-}
containsText : TextData -> Assertion
containsText { text, selector } =
  Native.Spec.containsText text selector


{-| Checks if the given attribute of an element contains the expected value.
-}
attributeContains : AttributeData -> Assertion
attributeContains { text, selector, attribute } =
  Native.Spec.attributeContains attribute text selector


{-| Checks if the given attribute of an element has the expected value.
-}
attributeEquals : AttributeData -> Assertion
attributeEquals { text, selector, attribute} =
  Native.Spec.attributeEquals attribute text selector


{-| Checks if the given element has the specified class.
-}
classPresent : ClassData -> Assertion
classPresent { class, selector } =
  Native.Spec.classPresent class selector


{-| Checks if the given element given computed style equals the expected value.
-}
styleEquals : StyleData -> Assertion
styleEquals { style, value, selector } =
  Native.Spec.styleEquals style value selector


{-| Checks if the given element exists in the DOM.
-}
elementPresent : String -> Assertion
elementPresent =
  Native.Spec.elementPresent

{-| Checks if the given element is disabled in the DOM.
-}
elementDisabled : String -> Assertion
elementDisabled =
  Native.Spec.elementDisabled


{-| Checks if the given element is visible on the page.
-}
elementVisible : String -> Assertion
elementVisible =
  Native.Spec.elementVisible


{-| Checks if the given checkbox is checked on the page.
-}
checkboxChecked: String -> Assertion
checkboxChecked =
  Native.Spec.checkboxChecked


{-| Checks if the page title contains the given value.
-}
titleContains : String -> Assertion
titleContains =
  Native.Spec.titleContains


{-| Checks if the page title contains the given value.
-}
titleEquals : String -> Assertion
titleEquals =
  Native.Spec.titleEquals


{-| Checks if the current URL contains the given value.
-}
urlContains : String -> Assertion
urlContains =
  Native.Spec.urlContains


{-| Checks if the current body contains the given value.
-}
bodyContains : String -> Assertion
bodyContains =
  Native.Spec.bodyContains


{-| Checks if the current url equals the given value.
-}
urlEquals : String -> Assertion
urlEquals =
  Native.Spec.urlEquals


{-| Checks if the given form element's value contains the expected value.
-}
valueContains : TextData -> Assertion
valueContains { text, selector } =
  Native.Spec.valueContains text selector


{-| Checks if the given form element's value equals the expected value.
-}
valueEquals : TextData -> Assertion
valueEquals { text, selector } =
  Native.Spec.valueEquals text selector


{-| Checks if the given element given inline style equals the expected value.
-}
inlineStyleEquals : StyleData -> Assertion
inlineStyleEquals { style, value, selector } =
  Native.Spec.inlineStyleEquals style value selector


{-| For a given selector, gets element, clears a value and triggers dom event for its element.
-}
clearValueAndDispatch : EventData -> Step
clearValueAndDispatch { selector, eventName } =
  Native.Spec.clearValueAndDispatch selector eventName

{-| For a given selector, gets element, set it's value and dispatch an event.
-}
setValueAndDispatch : ValueWithEventData -> Step
setValueAndDispatch { value, selector, eventName } =
  Native.Spec.setValueAndDispatch value selector eventName

{-|-}
unsafeInvocationCount: comparable -> Task Never Int
unsafeInvocationCount id =
  Native.Spec.unsafeInvocationCount id