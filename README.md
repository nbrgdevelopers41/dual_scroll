# A Flutter plugin to provide platform independent/dependant scrolling and panning functionality

## Features

* This package can scroll horizontally and vertically, the scroll is locked once it is scrolled in a particular direction.
* This package uses touch gestures on Mobile Platforms and Mouse/Trackpad inputs on Desktop/Web.

## Note

* We have removed the [`synaptics_driver_fix_windows`][6] package as it is discontinued.

## Getting started

 Add ```dual_scroll: ^0.0.9``` to your pubspec.yaml under `dependencies` section as follows.

 ```yaml
 dependencies:
# Your other dependencies...
   dual_scroll: any
# Your other dependencies...
 ```

 Run ```flutter pub get``` to get the package.

 Alternatively, your editor might support

 ```flutter pub get```

## Usage

Start by importing the package

```dart
import 'package:dual_scroll/dual_scroll.dart';
```

Use by wrapping the Widget You want to be scrollable in the following way:

```dart
return DualScroll(
    verticalScrollbar: ScrollBar.defaultScrollBar(),
    horizontalScrollbar: ScrollBar.defaultScrollBar(),
    child: Container(), /* Your child widget here*/
);
```

## Usage with ListView/GridView/Scrollable Widgets as Child/Children

To use the `DualScroll` widget while having a ListView/GridView/Scrollable Widget(s) as its child/children, initialize DualScroll in this way:

```dart
return DualScroll(
    verticalScrollController: yourVerticalScrollController,
    horizontalScrollController: yourHorizontalScrollController,
    verticalScrollbar: ScrollBar.defaultScrollBar(),
    horizontalScrollbar: ScrollBar.defaultScrollBar(),
    child: Container(), /* Your child widget here*/
);
```

## Customizing Additional Properties

You can pass `ScrollBarSettings` to the DualScroll widget in the constructor with appropriate parameter (It is not necessary to provide all parameters):

```dart
var scrollBarSettings = ScrollBarSettings(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, // Defaults to ScrollViewKeyboardDismissBehavior.manual
    clipBehavior: Clip.none, // Defaults to [Clip.hardEdge]
    verticalRestorationId: 'vertId', // Defaults to null
    horizontalRestorationId: 'horizId', // Defaults to null
    verticalPhysics = const ClampingScrollPhysics(), // Defaults to BouncingScrollPhysics
    horizontalPhysics = const ClampingScrollPhysics(), // Defaults to BouncingScrollPhysics
    verticalPadding: const EdgeInsets.all(8.0), //Defaults to null
    horizontalPadding: const EdgeInsets.all(8.0), //defaults to null
  );
  
  return DualScroll(
        // scrollBars and scrollControllers here
        settings: scrollBarSettings, //Optional
        pillColor: Colors.blueAccent, //Optional
        dimmedPillColor: Colors.blueAccent.withOpacity(0.8), //Optional
        trackColor: Colors.blueAccent.withOpacity(0.8), //Optional
        trackColorDimmed: Colors.blueAccent.withOpacity(0.6), //Optional
        hoverColor: Colors.blue.withOpacity(0.85), //Optional
        child: child, // Required
    );
```

## Additional information

If you experience any issues, please file those [here on Github][1]. If you want to contribute to this repo, open a PR on [Github][2]. If you want to view the API in detail, visit [dual_scroll on our website][3].

Also, We would really appreciate if you view our [website][4] and our [apps][5].

[1]: https://github.com/nbrgdevelopers41/dual_scroll/issues

[2]: https://github.com/nbrgdevelopers41/dual_scroll/pulls

[3]: https://nbrg-developers.web.app/docs/plugins/flutter/dual_scroll

[4]: https://nbrg-developers.web.app

[5]: https://nbrg-developers.web.app/services/one-nbrg/apps

[6]: https://pub.dev/packages/synaptics_driver_fix_windows
