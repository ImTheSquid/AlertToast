# AlertToast-SwiftUI
### Present Apple-like alerts & toasts in SwiftUI

This is a fork of the original repo that fixes issues with presenting in sheets. However, this version has the limitation that only one alert may be presented at any given time.

<p align="center">
   <img src="https://github.com/elai950/AlertToast/blob/master/Assets/GithubCoverNew.png" width="480"/>
</p>

## 🌄 Examples

<p align="center">
    <img src="https://github.com/elai950/AlertToast/blob/master/Assets/onboarding.png" style="display: block; margin: auto;"/>
</p>

<p align="center">
    <img src="https://github.com/elai950/AlertToast/blob/master/Assets/ToastExample.gif" style="display: block; margin: auto;" width="180"/>
</p>

## 🔭 Overview

Currently in SwiftUI, the only way to inform the user about, for example, some process that finished, is by using `Alert`. Sometimes you just want to show a message that tells the user that something completed, or that a message was sent. Apple doesn't provide any other method rather than using `Alert` even though Apple uses all kinds of different pop-ups internally. The results is poor UX where the user needs to tap "OK/Dismiss" for every bit of information that they are notified about.

Alert Toast is an open-source library in Github to use with SwiftUI. It allows you to present popups that don't need any user action to dismiss or validate. Some great usage examples: `Message Sent`, `Poor Network Connection`, `Profile Updated`, `Logged In/Out`, `Favorited`, `Loading`, and so on.

<img src="https://img.shields.io/badge/PLATFORM-IOS%20|%20MACOS-lightgray?style=for-the-badge" />&nbsp;&nbsp;&nbsp;<img src="https://img.shields.io/badge/LICENSE-MIT-lightgray?style=for-the-badge" />&nbsp;&nbsp;&nbsp;<img src="https://img.shields.io/badge/MADE WITH-SWIFTUI-orange?style=for-the-badge" />

* Built with pure SwiftUI.
* 3 Display modes: `Alert` (pop at the center), `HUD` (drop from the top) and `Banner` (pop/slide from the bottom).
* `Complete`, `Error` `SystemImage`, `Image`, `Loading`, and `Regular` (Only Text).
* Supports Light & Dark Mode.
* Works with **any** kind of view builder.
* Localization support.
* Font & Background customization.

## Navigation

- [Installation](#-installation)
    - [Swift Package Manager](#swift-package-manager)
    - [Manually](#manually)
- [Usage](#-usage)
    - [Usage example with regular alert](#usage-example-with-regular-alert)
    - [Complete Modifier Example](#complete-modifier-example)
    - [Alert Toast Parameters](#alert-toast-parameters)
 - [Article](#-article)
 - [Contributing](#-contributing)
 - [Author](#-author)
 - [License](#-license)

## 💻 Installation

### Swift Package Manager

[Swift Package Manager](https://swift.org/package-manager/) is a tool for managing the distribution of Swift code. It’s integrated with the Swift build system to automate the process of downloading, compiling, and linking dependencies.

To integrate `AlertToast` into your Xcode project using Xcode 12, specify it in `File > Swift Packages > Add Package Dependency...`:

```ogdl
https://github.com/ImTheSquid/AlertToast.git, :branch="master"
```

For Xcode 13, please refer [this article](https://iiroalhonen.medium.com/adding-a-swift-package-dependency-in-xcode-13-937b2caaf218) to install `AlertToast` 

------

### Manually

If you prefer not to use any of dependency managers, you can integrate `AlertToast` into your project manually. Put `Sources/AlertToast` folder in your Xcode project. Make sure to enable `Copy items if needed` and `Create groups`.

## 🧳 Requirements

- iOS 13.0+ | macOS 11+
- Swift 5+

## 🛠 Usage

First add `import AlertToast` to every `swift` file where you would like to use `AlertToast`.

Then in a root view (for example `[AppNameHere]App` or the first view in a sheet), add this modifier:
```swift
var body: some View {
    Group {
        // ...
    } // End of View declaration
    .alertToastRoot()
}
```

This allows alerts to be anchored to any root view of your choosing. Keep in mind that this always works on the farthest down view, so only put this in your root views!

Then use the `.toast` view modifier:

**Parameters:**

- `isPresenting`: (MUST) assign a `Binding<Bool>` to show or dismiss alert.
- `duration`: default is 2, set 0 to disable auto dismiss.
- `tapToDismiss`: default is `true`, set `false` to disable.
- `alert`: (MUST) expects `AlertToast`.

#### Usage example with regular alert

```swift 
import AlertToast
import SwiftUI

struct ContentView: View{

    @State private var showToast = false

    var body: some View{
        VStack{

            Button("Show Toast"){
                 showToast.toggle()
            }
        }
        .toast(isPresenting: $showToast){

            // `.alert` is the default displayMode
            AlertToast(type: .regular, title: "Message Sent!")
            
            //Choose .hud to toast alert from the top of the screen
            //AlertToast(displayMode: .hud, type: .regular, title: "Message Sent!")
            
            //Choose .banner to slide/pop alert from the bottom of the screen
            //AlertToast(displayMode: .banner(.slide), type: .regular, title: "Message Sent!")
        }
    }
}
```

#### Complete Modifier Example

```swift
.toast(isPresenting: $showAlert, duration: 2, tapToDismiss: true, alert: {
   //AlertToast goes here
}, onTap: {
   //onTap would call either if `tapToDismis` is true/false
   //If tapToDismiss is true, onTap would call and then dismis the alert
}, completion: {
   //Completion block after dismiss
})
```

### Alert Toast Parameters

```swift
AlertToast(displayMode: DisplayMode,
           type: AlertType,
           title: Optional(String),
           subTitle: Optional(String),
           style: Optional(AlertStyle))
           
//This is the available customizations parameters:
AlertStyle(backgroundColor: Color?,
            titleColor: Color?,
            subTitleColor: Color?,
            titleFont: Font?,
            subTitleFont: Font?)
```

#### Available Alert Types:
- **Regular:** text only (Title and Subtitle).
- **Complete:** animated checkmark.
- **Error:** animated xmark.
- **System Image:** name image from `SFSymbols`.
- **Image:** name image from Assets.
- **Loading:** Activity Indicator (Spinner).

#### Alert dialog view modifier (with default settings):
```swift
.toast(isPresenting: Binding<Bool>, duration: Double = 2, tapToDismiss: true, alert: () -> AlertToast , onTap: () -> (), completion: () -> () )
```

#### Simple Text Alert:
```swift
AlertToast(type: .regular, title: Optional(String), subTitle: Optional(String))
```

#### Complete/Error Alert:
```swift
AlertToast(type: .complete(Color)/.error(Color), title: Optional(String), subTitle: Optional(String))
```

#### System Image Alert:
```swift
AlertToast(type: .systemImage(String, Color), title: Optional(String), subTitle: Optional(String))
```

#### Image Alert:
```swift
AlertToast(type: .image(String), title: Optional(String), subTitle: Optional(String))
```

#### Loading Alert:
```swift
//When using loading, duration won't auto dismiss and tapToDismiss is set to false
AlertToast(type: .loading, title: Optional(String), subTitle: Optional(String))
```

You can add multiple `.toast`s on a single view.

## 👨‍💻 Contributors

All issue reports, feature requests, pull requests and GitHub stars are welcomed and much appreciated.

- [@barnard-b](https://github.com/barnard-b)

## ✍️ Author

Jack Hogan & Elai Zuberman

## 📃 License

`AlertToast` is available under the MIT license. See the [LICENSE](https://github.com/ImTheSquid/AlertToast/blob/master/LICENSE.md) file for more info.

---

- [Jump Up](#-overview)
