//
//  Label.swift
//  BindableViews
//
//  Created by Nathan Hosselton on 7/5/19.
//  Copyright © 2019 Nathan Hosselton. All rights reserved.
//

import UIKit.UILabel

public typealias Text = Label

/// A subclass of `UILabel` which accepts a `Binding` for updating changes to its text.
public final class Label: UILabel, BindableView {

    /// Sets the starting font for all future instances of `Label`.
    /// - Important: When customizing this value per-controller, it must be set prior to the
    /// `layout` initialization within the view lifecycle (sometime before `super.viewDidLoad`).
    static var defaultFont: UIFont = .preferredFont(forTextStyle: .body)

    /// The value binding to this view's `text` property. Updates to the binding reflect automatically.
    private(set) weak var binding: Binding<String>?

    /// The designated initializer for this class. Takes a binding which is used to update this view's text.
    /// - parameter binding: The value binding to this view's `text` property.
    init(_ binding: Binding<String>) {
        self.binding = binding
        super.init(frame: .zero)
        font = Label.defaultFont
        binding.observe { [weak self] in self?.text = $0 }
    }

    /// Initializes a new `Label` with a constant value instead of a binding.
    /// - Note: This initializer assumes that this label's text will remain static and so a binding will not
    /// be provided nor can one be later assigned. If you simply wish for the label to have an initial value
    /// for its `text`, call `startingValue(:)` after initializing with a binding.
    /// - parameter text: The value to set for this label's `text`.
    /// - Seealso: `startingValue(:)`
    init(_ text: String) {
        super.init(frame: .zero)
        self.text = text
        font = Label.defaultFont
    }

    /// A convenience initializer that takes a `String` binding and adjacent constants which are
    /// concatenated to the binding value each update.
    /// - Parameters:
    ///     - prefix: The string value to prepend to the binding value.
    ///     - binding: The value binding used to update this view's `text` property.
    ///     - suffix: The string value to append to the binding value.
    init(_ prefix: String, _ binding: Binding<String>, _ suffix: String) {
        self.binding = binding
        super.init(frame: .zero)
        font = Label.defaultFont
        binding.observe { [weak self] in self?.text = prefix + $0 + suffix}
    }

    /// A convenience initializer that takes a `String` binding and an adjacent constant that is
    /// concatenated to the binding value each update.
    /// - Parameters:
    ///     - prefix: The string value to prepend to the binding value.
    ///     - binding: The value binding used to update this view's `text` property.
    convenience init(_ prefix: String, _ binding: Binding<String>) {
        self.init(prefix, binding, "")
    }

    /// A convenience initializer that takes a `String` binding and an adjacent constant that is
    /// concatenated to the binding value each update.
    /// - Parameters:
    ///     - binding: The value binding used to update this view's `text` property.
    ///     - suffix: The string value to append to the binding value.
    convenience init(_ binding: Binding<String>, _ suffix: String) {
        self.init("", binding, suffix)
    }

    /// Performs the provided transform to this label's `text` when the condition is met.
    ///
    /// Observes the provided binding, checking its value when updated and conditionally executing the
    /// provided transform, setting its returned value as the new `text` for the label.
    /// - Important: The provided binding is not retained, but the transform _is_. Do not
    ///     pass methods without proper consideration for retain cycles.
    /// - Parameters:
    ///   - binding: The boolean value binding to observe for executing the transform.
    ///   - is: Optional comparitor for the `binding`'s value. Defaults to `true`.
    ///   - transform: A function whose result is assigned as the label's new `text` value.
    func transforming(when binding: Binding<Bool>, is: Bool = true, _ transform: @escaping () -> String) -> Self {
        binding.observe { [weak self] in
            if $0 == `is` {
                self?.text = transform()
            }
        }
        return self
    }

    /// Sets the alignment of the text within the Label.
    /// - parameter alignment: The alignment to be used.
    func alignment(_ alignment: NSTextAlignment) -> Self {
        textAlignment = alignment
        return self
    }

    /// Sets the baseline adjustment of the text within the Label.
    /// - parameter baseline: The baseline adjustment to be used.
    func baselineAdjustment(_ baseline: UIBaselineAdjustment) -> Self {
        baselineAdjustment = baseline
        return self
    }

    /// Sets the kerning of this label's text.
    ///
    /// If the label has static text, the kerning is immediately set. If the label receives its text from
    /// a binding, the binding is observed and kerning is set on each update.
    /// - parameter amount: The amount of kerning to apply.
    func kerning(_ amount: CGFloat) -> Self {
        let kern: (String) -> Void = { [weak self] text in
            let kerned: NSMutableAttributedString

            if let attributed = self?.attributedText {
                kerned = NSMutableAttributedString(attributedString: attributed)
            } else {
                kerned = NSMutableAttributedString(string: text)
            }

            kerned.addAttribute(.kern, value: amount, range: NSRange(location: 0, length: kerned.length))
            self?.attributedText = kerned
        }

        if let text = text, text.count > 0 {
            kern(text)
        }

        binding?.observe(with: kern)

        return self
    }

    /// Sets the font.
    /// - Note: If `adjustsFontSizeRelativeToDisplay` has been set, the size of the font will be scaled.
    /// - parameter font: The font to be used for text.
    /// - Seealso: `fontFamily(:)`, `fontFace(:)`
    func font(_ font: UIFont) -> Self {
        self.font = font.withSize(displayScale.scaleWithHeight(font.pointSize))
        return self
    }

    /// Set the font using the provided font name and preserving the current font size.
    /// - parameter name: The full name of the font to be used, e.g. `"HelveticaNeue-LightItalic"`.
    /// - SeeAlso: `font(_ font:)`
    func font(_ name: String) -> Self {
        font = UIFont(name: name, size: font.pointSize)
        return self
    }

    /// Sets the font using a descriptor.
    /// - Note: If `adjustsFontSizeRelativeToDisplay` has been set, the size of the font provided
    ///   in the descriptor will be scaled.
    /// - parameter descriptor: The descriptor to use for setting the font.
    func font(from descriptor: UIFontDescriptor) -> Self {
        let size: CGFloat
        if descriptor.pointSize > 0 {
            size = displayScale.scaleWithHeight(descriptor.pointSize)
        } else {
            size = font.pointSize
        }
        font = UIFont(descriptor: descriptor, size: size)
        return self
    }

    /// Sets the font to the provided type family, preserving the current font size.
    /// - parameter family: The name of the type family to be used, e.g. `"Helvetica"`.
    func fontFamily(_ family: String) -> Self {
        font = UIFont(name: family, size: font.pointSize)
        return self
    }

    /// Sets the face of the current font.
    /// - parameter face: The name of the font face to be used, e.g. `"Light Oblique"`.
    /// - Note: No effect when the current font does not support the provided face name.
    func fontFace(_ face: String) -> Self {
        let descriptor = font.fontDescriptor.withFace(face)
        font = UIFont(descriptor: descriptor, size: font.pointSize)
        return self
    }

    /// Sets the size of the current font.
    /// - Note: If `adjustsFontSizeRelativeToDisplay` has been set, the provided size will be scaled.
    /// - parameter size: The size to use for the current font, in points.
    func fontSize(_ size: CGFloat) -> Self {
        font = font.withSize(displayScale.scale(size))
        return self
    }

    /// Sets the color of the displayed text.
    /// - parameter color: The color to be used for the text.
    func color(_ color: UIColor) -> Self {
        textColor = color
        return self
    }

    /// Sets the line break mode for the label
    /// - parameter mode: The line break mode to use.
    func lineBreakMode(_ mode: NSLineBreakMode) -> Self {
        lineBreakMode = mode
        return self
    }

    /// Sets the number of lines for the label.
    /// - parameter lines: The number of lines.
    func numberOfLines(_ lines: Int) -> Self {
        numberOfLines = lines
        return self
    }

    /// Enables decreasing of the label's font size to fit its text within its bounding rect, optionally
    /// taking a minimum scale factor to set.
    /// - parameter minimumFactor: The minimum scale factor to use when the font size is shrunk.
    func adjustsFontSizeToFitWidth(minimumFactor: CGFloat? = nil) -> Self {
        adjustsFontSizeToFitWidth = true
        if let minimum = minimumFactor {
            minimumScaleFactor = minimum
        }
        return self
    }

    /// Enables decreasing or increasing of the lable's font size relative to the provided display scale.
    /// This method immediately updates the current font size when called.
    /// - parameter scale: The display scale to use for scaling the font. That is, the display scale
    ///   for which the font size will remain unchanged.
    func adjustsFontSizeRelativeToDisplay(_ scale: DisplayScale) -> Self {
        displayScale = scale
        return self
    }

    func styleProvider(_ provider: (_ stylable: UILabel) -> Void) -> Self {
        provider(self)
        return self
    }

    private var displayScale = DisplayScale.any {
        didSet {
            font = font.withSize(displayScale.scaleWithHeight(font.pointSize))
        }
    }

    //MARK: Unavailable

    @available(*, unavailable)
    required init(coder: NSCoder = .empty) {
        fatalError("\(#file + #function) is not available.")
    }

    @available(*, unavailable)
    override init(frame: CGRect) {
        fatalError("\(#file + #function) is not available.")
    }
}

enum DisplayScale: CGFloat, Comparable {
    /// The maximum scaling factor to observe in calculations. Higher values will be ignored.
    static var maxScaling = DisplayScale.x1112

    /// Scaling is not performed.
    case any = 1.0
    /// Scales relative to devices with a width of `320` points.
    case x320 = 320.0
    /// Scales relative to devices with a width of `375` points.
    case x375 = 375.0
    /// Scales relative to devices with a width of `414` points.
    case x414 = 414.0
    /// Scales relative to devices with a width of `1024` points.
    case x1024 = 1024.0
    /// Scales relative to devices with a width of `1112` points.
    case x1112 = 1112.0

    /// The maximum possible height for the width class. Used for scaling with height.
    private var maxHeight: CGFloat {
        switch self {
        case .any:
            return 1.0
        case .x320:
            return 568.0
        case .x375:
            //NOTE: Technically this value should be 812.0 (iPhone X), but in practice
            //that's an unfair value to scale against due to the large safe areas at
            //the top and bottom of X displays. This value (for x414 displays) ends up
            //scaling exactly as expected.
            return 736.0
        case .x414:
            return 736.0
        case .x1024:
            return 1366.0
        case .x1112:
            return 834.0
        }
    }

    /// Returns the provided value scaled to the current display width relative to self.
    /// - parameter value: The value to scale.
    func scale(_ value: CGFloat) -> CGFloat {
        guard self != .any else { return value }
        let scale = min(UIScreen.main.bounds.width, DisplayScale.maxScaling.rawValue) / rawValue
        return value * scale
    }

    /// Returns the provided value scaled to the current display size relative to self.
    ///
    /// The display's width and height are considered, the latter of which relative to the maximum
    /// possible height for the width class. The smallest scale factor is used to scale the result.
    /// - parameter value: The value to scale.
    func scaleWithHeight(_ value: CGFloat) -> CGFloat {
        guard self != .any else { return value }
        let widthScale = min(UIScreen.main.bounds.width, DisplayScale.maxScaling.rawValue) / rawValue
        let heightScale = min(UIScreen.main.bounds.height, DisplayScale.maxScaling.maxHeight) / maxHeight
        let scale = abs(1 - widthScale) > abs(1 - heightScale) ? widthScale : heightScale
        return value * scale
    }

    static func < (lhs: DisplayScale, rhs: DisplayScale) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

extension UIScreen {
    /// The `DisplayScale` that will be used on this device based on its screen size.
    var displayScale: DisplayScale {
        switch bounds.width {
        case 320.0: return .x320
        case 375.0: return .x375
        case 414.0: return .x414
        case 1024.0: return .x1024
        case 1112.0: return .x1112
        default:
            return .any
        }
    }
}

extension Label {
    static func + (lhs: Label, rhs: Label) -> UIStackView {
        return UIStackView(arrangedSubviews: [lhs, rhs])
    }

    static func + (lhs: UIStackView, rhs: Label) -> UIStackView {
        lhs.addArrangedSubview(rhs)
        return lhs
    }
}
