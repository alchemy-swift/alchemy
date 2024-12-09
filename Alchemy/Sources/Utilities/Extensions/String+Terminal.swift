import Foundation

extension String {

    // MARK: Color

    /// String with black text.
    public var black: String { Container.isXcode ? self : applyingColor(.black) }
    /// String with red text.
    public var red: String { Container.isXcode ? self : applyingColor(.red)   }
    /// String with green text.
    public var green: String { Container.isXcode ? self : applyingColor(.green) }
    /// String with yellow text.
    public var yellow: String { Container.isXcode ? self : applyingColor(.yellow) }
    /// String with blue text.
    public var blue: String { Container.isXcode ? self : applyingColor(.blue) }
    /// String with magenta text.
    public var magenta: String { Container.isXcode ? self : applyingColor(.magenta) }
    /// String with cyan text.
    public var cyan: String { Container.isXcode ? self : applyingColor(.cyan) }
    /// String with white text.
    public var white: String { Container.isXcode ? self : applyingColor(.white) }
    /// String with light black text. Generally speaking, it means dark grey in some consoles.
    public var lightBlack: String { Container.isXcode ? self : applyingColor(.lightBlack) }
    /// String with light red text.
    public var lightRed: String { Container.isXcode ? self : applyingColor(.lightRed) }
    /// String with light green text.
    public var lightGreen: String { Container.isXcode ? self : applyingColor(.lightGreen) }
    /// String with light yellow text.
    public var lightYellow: String { Container.isXcode ? self : applyingColor(.lightYellow) }
    /// String with light blue text.
    public var lightBlue: String { Container.isXcode ? self : applyingColor(.lightBlue) }
    /// String with light magenta text.
    public var lightMagenta: String { Container.isXcode ? self : applyingColor(.lightMagenta) }
    /// String with light cyan text.
    public var lightCyan: String { Container.isXcode ? self : applyingColor(.lightCyan) }
    /// String with light white text. Generally speaking, it means light grey in some consoles.
    public var lightWhite: String { Container.isXcode ? self : applyingColor(.lightWhite) }

    // MARK: Style

    /// String with bold style.
    public var bold: String { Container.isXcode ? self : applyingStyle(.bold) }
    /// String with dim style. This is not widely supported in all terminals. Use it carefully.
    public var dim: String { Container.isXcode ? self : applyingStyle(.dim) }
    /// String with italic style. This depends on whether an italic existing for the font family of terminals.
    public var italic: String { Container.isXcode ? self : applyingStyle(.italic) }
    /// String with underline style.
    public var underline: String { Container.isXcode ? self : applyingStyle(.underline) }
    /// String with blink style. This is not widely supported in all terminals, or need additional setting. Use it carefully.
    public var blink: String { Container.isXcode ? self : applyingStyle(.blink) }
    /// String with text color and background color swapped.
    public var swap: String { Container.isXcode ? self : applyingStyle(.swap) }
}

