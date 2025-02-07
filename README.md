# Swift Declarative Configuration

[![Test](https://github.com/CaptureContext/swift-declarative-configuration/actions/workflows/Test.yml/badge.svg)](https://github.com/CaptureContext/swift-declarative-configuration/actions/workflows/Test.yml) [![SwiftPM 5.6](https://img.shields.io/badge/swiftpm-5.6-ED523F.svg?style=flat)](https://swift.org/download/) ![Platforms](https://img.shields.io/badge/platforms-iOS_11_|_macOS_10.13_|_tvOS_11_|_watchOS_4_|_Catalyst_13-ED523F.svg?style=flat) [![@capture_context](https://img.shields.io/badge/contact-@capture__context-1DA1F2.svg?style=flat&logo=twitter)](https://twitter.com/capture_context) 

Swift Declarative Configuration (SDC, for short) is a tiny library, that enables you to configure your objects in a declarative, consistent and understandable way, with ergonomics in mind. It can be used to configure any objects on any platform, including server-side-swift.

## Products

- **[FunctionalModification](./Sources/FunctionalModification)**

  Provides modification functions for copying and modifying immutable stuff. It is useful for self-configuring objects like builder, when modificating methods should return modified `self`

- **[FunctionalKeyPath](./Sources/FunctionalKeyPath)**

  Functional KeyPath wrapper.

- **[FunctionalConfigurator](./Sources/FunctionalConfigurator)**

  Funtional configurator for anything, enables you to specify modification of an object and to apply the modification later.

  Also contains self-implementing protocols (`ConfigInitializable`,  `CustomConfigurable`) to enable you add custom configuration support for your types (`NSObject` already conforms to it for you).

- **[FunctionalBuilder](./Sources/FunctionalBuilder)**

  Functional builder for anything, enables you to modify object instances in a declarative way. Also contains `BuilderProvider` protocol with a computed `builder` property and implements that protocol on `NSObject` type.

- **[FunctionalClosures](./Sources/FunctionalClosures)**

  Functional closures allow you to setup functional handlers & datasources, the API may seem a bit strange at the first look, so feel free to ask or discuss anything [here](https://github.com/MakeupStudio/swift-declarative-configuration/issues/1).

- **[DeclarativeConfiguration](./Sources/DeclarativeConfiguration)**

  Wraps and exports all the products.

## Basic Usage

> **See tests for more**

### No SDC

```swift
class ImageViewController: UIViewController {
  let imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFit
    imageView.backgroundColor = .black
    imageView.layer.masksToBounds = true
    imageView.layer.cornerRadius = 10
    return imageView
  }()
    
  override func loadView() {
    self.view = imageView
  }
}
```

### FunctionalConfigurator

> **Note:** This way is **recommended**, but remember, that custom types **MUST** implement initializer with no parameters even if the superclass already has it or you will get a crash otherwise.

```swift
import FunctionalConfigurator

class ImageViewController: UIViewController {
  let imageView = UIImageView { $0 
    .contentMode(.scaleAspectFit)
    .backgroundColor(.black)
    .layer.scope { $0
      .masksToBounds(true)
      .cornerRadius(10)
    }
  }
    
  override func loadView() {
    self.view = imageView
  }
}
```

### FunctionalBuilder

> **Note:** This way is recommended too, and it is more **safe**, because it modifies existing objects.

```swift
import FunctionalBuilder

class ImageViewController: UIViewController {
  let imageView = UIImageView().builder
    .contentMode(.scaleAspectFit)
    .backgroundColor(.black)
    .layer.masksToBounds(true)
    .layer.cornerRadius(10)
    .build()
    
  override func loadView() {
    self.view = imageView
  }
}
```

### FunctionalClosures

### No SDC

**Declaration**

```swift
public class TapGestureRecognizer: UITapGestureRecognizer {
  var onTapGesture: ((TapGestureRecognizer) -> Void)?
    
  init() {
    super.init(target: nil, action: nil)
    commonInit()
  }
    
  override public init(target: Any?, action: Selector?) {
    super.init(target: target, action: action)
    commonInit()
  }
    
  private func commonInit() {
    self.addTarget(self, action: #selector(handleTap))
  }
    
  @objc private func handleTap(_ recognizer: TapGestureRecognizer) {
    onTapGesture?(recognizer)
  }
}
```

**Usage**

```swift
let tapRecognizer = TapGestureRecognizer()

// handler setup
tapRecognizer.onTapGesture = { recognizer in
	// ...
}

// call from the outside
tapRecognizer.onTapGesture?(tapRecognizer)
```

### With SDC

**Declaration**

```swift
public class TapGestureRecognizer: UITapGestureRecognizer {
  @Handler<TapGestureRecognizer>
  var onTapGesture
    
  init() {
    super.init(target: nil, action: nil)
    commonInit()
  }
    
  override public init(target: Any?, action: Selector?) {
    super.init(target: target, action: action)
    commonInit()
  }
    
  private func commonInit() {
    self.addTarget(self, action: #selector(handleTap))
  }
    
  @objc private func handleTap(_ recognizer: TapGestureRecognizer) {
    _onTapGesture(recognizer)
  }
}
```

**Usage**

```swift
let tapRecognizer = TapGestureRecognizer()

// handler setup now called as function
tapRecognizer.onTapGesture { recognizer in
	// ...
}

// call from the outside now uses propertyWrapper projectedValue API, which is not as straitforward
// and it is nice, because:
// - handlers usually should not be called from the outside
// - you do not lose the ability to call it, but an API tells you that it's kinda private
tapRecognizer.$onTapGesture?(tapRecognizer)
```

Also you can create such an instance with `Configurator`:

```swift
let tapRecognizer = TapGestureRecognizer { $0 
  .$onTapGesture { recognizer in 
    // ...
  }
}
```

### More

#### Builder

Customize any object by passing initial value to a builder

```swift
let object = Builder(Object())
  .property.subproperty(value)
  .build() // Returns modified object
```

For classes you can avoid returning a value by calling `apply` method, instead of `build`

```swift
let _class = _Class()
Builder(_class)
  .property.subproperty(value)
  .apply() // Returns Void
```

In both Builders and Configurators you can use scoping

```swift
let object = Object { $0
  .property.subproperty(value)
}
```



Conform your own types to `BuilderProvider` protocol to access builder property.

```swift
import CoreLocation
import DeclarativeConfiguration

extension CLLocationCoordinate2D: BuilderProvider {}
// Now you can access `location.builder.latitude(0).build()`
```

#### Configurator

> **Note:** Your NSObject classes **must** implement `init()` to use Configurators. It's a little trade-off for the convenience it brings to your codebase, see [tests](./Tests/DeclarativeConfigurationTests/ConfiguratorTests.swift) for an example.

#### DataSource

`OptionalDataSource` and `DataSource` types are very similar to the `Handler`, but if `Handler<Input>` is kinda `OptionalDataSource<Input, Void>`, the second one may have different types of an output. Usage is similar, different types are provided just for better semantics.

## Installation

### Basic

You can add DeclarativeConfiguration to an Xcode project by adding it as a package dependency.

1. From the **File** menu, select **Swift Packages › Add Package Dependency…**
2. Enter [`"https://github.com/makeupstudio/swift-declarative-configuration"`](https://github.com/makeupstudio/swift-declarative-configuration) into the package repository URL text field
3. Choose products you need to link them to your project.

### Recommended

If you use SwiftPM for your project structure, add DeclarativeConfiguration to your package file. 

```swift
.package(
  url: "git@github.com:capturecontext/swift-declarative-configuration.git", 
  .upToNextMinor(from: "0.3.0")
)
```
or via HTTPS

```swift
.package(
  url: "https://github.com:capturecontext/swift-declarative-configuration.git", 
  .exact("0.3.0")
)
```

Do not forget about target dependencies:

```swift
.product(
    name: "DeclarativeConfiguration", 
    package: "swift-declarative-configuration"
)
```

## License

This library is released under the MIT license. See [LICENSE](./LICENSE) for details.
