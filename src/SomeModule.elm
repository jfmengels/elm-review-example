module SomeModule exposing (someValue)

import SomeOtherModule


someValue : Int
someValue =
    1


someOtherValue : Int
someOtherValue =
    SomeOtherModule.value + 1
