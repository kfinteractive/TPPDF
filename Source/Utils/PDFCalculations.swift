//
//  PDFCalculations.swift
//  TPPDF
//
//  Created by Philip Niedertscheider on 24/08/2017.
//
import UIKit

// swiftlint:disable function_body_length

/**
 A collection of static calculations
 */
internal enum PDFCalculations {

    // MARK: - INTERNAL STATIC FUNCS

    /**
     Calculates the frame, the string that fits in the given `container` and the remainding string.

     - parameter generator: Generator which is calculating
     - parameter container: Container where text is drawn
     - parameter text: Text which should be calculated and drawn

     - returns: Tuple of text `frame`, text which fits in frame and the remainding text which did not fit
     */
    internal static func calculateText(generator: PDFGenerator,
                                       container: PDFContainer,
                                       text: NSAttributedString) -> (frame: CGRect, render: NSAttributedString, remainder: NSAttributedString?) {
        let availableSize = calculateAvailableFrame(for: generator, in: container)
        let calcResult = calculateTextSizeAndRemainder(of: text, in: availableSize)
        let origin = calculateElementPosition(for: generator, in: container, with: calcResult.size)

        return (
            CGRect(origin: origin, size: calcResult.size),
            calcResult.text,
            calcResult.remainder
        )
    }

    internal struct TextCalculationResult {
        internal var text: NSAttributedString
        internal var size: CGSize
        internal var remainder: NSAttributedString?
    }

    /**
     Calculates the actual size of the text and the remainder which does not fit the given `bounds`

     - parameter text: Text which is calculated
     - paramter bounds: Bounds where text should fit

     - returns: Tuple of `text`, real `size of the text and the `remainder`
     */
    internal static func calculateTextSizeAndRemainder(of text: NSAttributedString,
                                                       in bounds: CGSize) -> TextCalculationResult {
        assert(bounds.width > 0, "Can't render text if no space available")

        let framesetter = CTFramesetterCreateWithAttributedString(text)
        let framePath = UIBezierPath(rect: CGRect(origin: .zero, size: bounds)).cgPath

        let textRange = CFRange(location: 0, length: text.length)

        // Get the frame that will do the rendering
        let frameRef = CTFramesetterCreateFrame(framesetter, textRange, framePath, nil)

        // Calculate the range of the string which actually fits in the frame
        let visibleRange = CTFrameGetVisibleStringRange(frameRef)

        // Calculate the actual size the string needs
        let drawnSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, visibleRange, nil, bounds, nil)

        let castedRange = NSRange(location: 0, length: visibleRange.length)
        let result = text.attributedSubstring(from: castedRange)
        var remainder: NSAttributedString?

        if visibleRange.length != textRange.length {
            let remainderRange = NSRange(location: visibleRange.length, length: textRange.length - visibleRange.length)
            remainder = text.attributedSubstring(from: remainderRange)
        }

        return TextCalculationResult(text: result, size: drawnSize, remainder: remainder)
    }

    /**
     Calculates the available bounds size in a given `container`

     - parameter generator: Generator doing the calculations
     - parameter container: Container which size is calculated

     - returns: Available bounds size
     */
    internal static func calculateAvailableFrame(for generator: PDFGenerator, in container: PDFContainer) -> CGSize {
        return CGSize(
            width: calculateAvailableFrameWidth(for: generator, in: container),
            height: calculateAvailableFrameHeight(for: generator, in: container)
        )
    }

    /**
     TODO: documentation
     */
    internal static func calculateAvailableFrameWidth(for generator: PDFGenerator, in container: PDFContainer) -> CGFloat {
        let columnInset = generator.columnState.getInset(for: container)
        return generator.document.layout.width
            - generator.layout.margin.left
            - generator.layout.margin.right
            - generator.layout.indentation.leftIn(container: container)
            - columnInset.left
            - generator.layout.indentation.rightIn(container: container)
            - columnInset.right
            - generator.currentPadding.left
            - generator.currentPadding.right
    }

    /**
     TODO: Documentation
     */
    internal static func calculateAvailableFrameHeight(for generator: PDFGenerator, in container: PDFContainer) -> CGFloat {
        let layout = generator.layout
        let pageLayout = generator.document.layout

        if container.isHeader || container.isFooter {
            return pageLayout.height
        } else {
            return pageLayout.height
                - layout.margin.top
                - layout.heights.maxHeaderHeight()
                - layout.heights.content
                - generator.currentPadding.bottom
                - layout.heights.maxFooterHeight()
                - layout.margin.bottom
        }
    }

    /**
     Calculates the position of an element with given `size` in the given `container

     - parameter generator: Generator doing the calculations
     - parameter container: Container where element is in
     - parameter size: Size of element

     - returns: Position of element
     */
    internal static func calculateElementPosition(for generator: PDFGenerator, in container: PDFContainer, with size: CGSize) -> CGPoint {
        return CGPoint(
            x: calculatePositionX(for: generator, in: container, with: size),
            y: calculatePositionY(for: generator, in: container, with: size)
        )
    }

    // MARK: - PRIVATE STATIC FUNCS
    /**
     TODO: Documentation
     */
    private static func calculatePositionX(for generator: PDFGenerator, in container: PDFContainer, with size: CGSize) -> CGFloat {
        let layout = generator.layout
        let columnInset = generator.columnState.getInset(for: container)

        if container.isLeft {
            return generator.layout.margin.left
                + layout.indentation.leftIn(container: container)
                + columnInset.left
                + generator.currentPadding.left
        } else if container.isRight {
            return generator.document.layout.width
                - generator.layout.margin.right
                - layout.indentation.rightIn(container: container)
                - size.width
                - columnInset.right
                - generator.currentPadding.right
        } else {
            return generator.layout.margin.left
                + layout.indentation.leftIn(container: container)
                + columnInset.left
                + generator.currentPadding.left
                + (generator.document.layout.width
                    - generator.layout.margin.left
                    - layout.indentation.leftIn(container: container)
                    - columnInset.left
                    - columnInset.right
                    - layout.indentation.rightIn(container: container)
                    - generator.layout.margin.right
                    - generator.currentPadding.left
                    - generator.currentPadding.right
                    - size.width
                ) / 2
        }
    }

    /**
     TODO: Documentation
     */
    private static func calculatePositionY(for generator: PDFGenerator, in container: PDFContainer, with size: CGSize) -> CGFloat {
        let layout = generator.layout
        let pageLayout = generator.document.layout

        if container.isHeader {
            return layout.margin.top
                + layout.heights.value(for: container)
        } else if container.isFooter {
            return pageLayout.height
                - layout.margin.bottom
                - layout.heights.value(for: container)
                - size.height
        } else {
            return layout.margin.top
                + layout.heights.maxHeaderHeight()
                + pageLayout.space.header
                + layout.heights.content
        }
    }

    /**
     TODO: Documentation
     */
    internal static func calculateContentOffset(for generator: PDFGenerator, of element: PDFObject, in container: PDFContainer) -> CGFloat {
        let layout = generator.layout
        let pageLayout = generator.document.layout

        if container.isHeader {
            return element.frame.minY
                - pageLayout.margin.top
        } else if container.isFooter {
            return element.frame.minY
                - (pageLayout.height
                    - pageLayout.margin.bottom
                    - layout.heights.value(for: container)
                    - element.frame.height)
        } else {
            return element.frame.minY
                - pageLayout.margin.top
                - layout.heights.maxHeaderHeight()
                - pageLayout.space.header
        }
    }

    /**
     TODO: Documentation
     */
    internal static func calculateContentOffset(for generator: PDFGenerator, of offset: CGFloat, in container: PDFContainer) -> CGFloat {
        let layout = generator.layout
        let pageLayout = generator.document.layout

        if container.isHeader {
            return offset
                - pageLayout.margin.top
        } else if container.isFooter {
            return offset
                - (pageLayout.height
                    - pageLayout.margin.bottom
                    - layout.heights.value(for: container))
        } else {
            return offset
                - pageLayout.margin.top
                - layout.heights.maxHeaderHeight()
                - pageLayout.space.header
        }
    }

    // MARK: - LEGACY

    /**
     TODO: Documentation
     */
    internal static func calculateCellFrame(generator: PDFGenerator,
                                            container: PDFContainer,
                                            position: (origin: CGPoint, width: CGFloat),
                                            text: NSAttributedString,
                                            alignment: PDFTableCellAlignment) -> CGRect {
        let textMaxHeight = PDFCalculations.calculateAvailableFrameHeight(for: generator, in: container)
        let frame: CGRect = CGRect(x: position.origin.x, y: position.origin.y, width: position.width, height: textMaxHeight)

        let currentRange = CFRange(location: 0, length: 0)
        let (_, _, drawnSize) = calculateTextFrameAndDrawnSizeInOnePage(frame: frame, text: text, currentRange: currentRange)
        let x: CGFloat = {
            if alignment.isLeft {
                return position.origin.x
            } else if alignment.isRight {
                return position.origin.x + position.width - drawnSize.width
            } else {
                return position.origin.x + position.width / 2 - drawnSize.width / 2
            }
        }()

        return CGRect(origin: CGPoint(x: x, y: position.origin.y), size: CGSize(width: drawnSize.width, height: drawnSize.height))
    }

    /**
     TODO: Documentation
     */
    internal static func calculateCellFrame(generator: PDFGenerator, origin: CGPoint, width: CGFloat, image: UIImage) -> CGRect {
        let imageSize = image.size
        let height = imageSize.height / imageSize.width * width

        return CGRect(x: origin.x, y: origin.y, width: width, height: height)
    }

    /**
     TODO: Documentation
     */
    internal static func calculateTextFrameAndDrawnSizeInOnePage(generator: PDFGenerator,
                                                                 container: PDFContainer,
                                                                 text: CFAttributedString,
                                                                 currentRange: CFRange,
                                                                 textMaxWidth: CGFloat) -> (CGRect, CTFrame, CGSize) {
        let textMaxWidth = (textMaxWidth > 0) ? textMaxWidth : (generator.document.layout.width
            - generator.layout.margin.left
            - generator.layout.margin.right
            - generator.layout.indentation.leftIn(container: container)
            - generator.layout.indentation.rightIn(container: container))

        let textMaxHeight: CGFloat = {
            if container.isHeader {
                return generator.document.layout.height
                    - generator.layout.heights.header[container]!
            } else if container.isFooter {
                return generator.layout.margin.bottom
            } else {
                return generator.document.layout.height
                    - generator.layout.heights.maxHeaderHeight()
                    - generator.document.layout.space.header
                    - generator.layout.heights.maxFooterHeight()
                    - generator.document.layout.space.footer
                    - generator.layout.heights.content
            }
        }()

        // Create a path object to enclose the text.
        let x: CGFloat = {
            switch container {
            case .headerLeft, .contentLeft, .footerLeft:
                return generator.layout.margin.left
                    + generator.layout.indentation.leftIn(container: container)
            case .headerCenter, .contentCenter, .footerCenter:
                return generator.document.layout.bounds.midX
                    - textMaxWidth / 2
            case .headerRight, .contentRight, .footerRight:
                return generator.document.layout.width
                    - generator.layout.margin.right
                    - textMaxWidth
            default:
                return 0
            }
        }()

        let frame: CGRect = {
            if container.isHeader {
                return CGRect(x: x,
                              y: 0,
                              width: textMaxWidth,
                              height: textMaxHeight)
            } else if container.isFooter {
                return CGRect(x: x,
                              y: generator.document.layout.height
                                - generator.layout.heights.footer[container]!,
                              width: textMaxWidth,
                              height: textMaxHeight)
            } else {
                return CGRect(x: x,
                              y: generator.layout.heights.content
                                + generator.layout.heights.maxHeaderHeight()
                                + generator.document.layout.space.header,
                              width: textMaxWidth,
                              height: textMaxHeight)
            }
        }()

        return calculateTextFrameAndDrawnSizeInOnePage(frame: frame, text: text, currentRange: currentRange)
    }

    /**
     TODO: Documentation
     */
    internal static func calculateTextFrameAndDrawnSizeInOnePage(frame: CGRect,
                                                                 text: CFAttributedString,
                                                                 currentRange: CFRange) -> (CGRect, CTFrame, CGSize) {
        let framesetter = CTFramesetterCreateWithAttributedString(text)
        let framePath = UIBezierPath(rect: frame).cgPath

        // Get the frame that will do the rendering.
        // The currentRange variable specifies only the starting point. The framesetter
        // lays out as much text as will fit into the frame.
        let frameRef = CTFramesetterCreateFrame(framesetter, currentRange, framePath, nil)

        // Update the current range based on what was drawn.
        let visibleRange = CTFrameGetVisibleStringRange(frameRef)

        // Update last drawn frame
        let drawnSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, visibleRange, nil, frame.size, nil)

        return (frame, frameRef, drawnSize)
    }

    /**
     TODO: Documentation
     */
    internal static func calculateImageCaptionSize(generator: PDFGenerator,
                                                   container: PDFContainer,
                                                   image: PDFImage,
                                                   size: CGSize,
                                                   sizeFit: PDFImageSizeFit) -> (CGSize, CGSize) {
        /* calculate the aspect size of image */
        let size = (size == CGSize.zero) ? image.size : size

        let maxWidth = min(size.width, calculateAvailableFrameWidth(for: generator, in: container))
        let maxHeight = min(size.height, calculateAvailableFrameHeight(for: generator, in: container))

        let wFactor = image.size.width / maxWidth
        let hFactor = image.size.height / maxHeight

        let factor: CGFloat = {
            switch sizeFit {
            case .width:
                return wFactor
            case .height:
                return hFactor
            case .widthHeight:
                return max(wFactor, hFactor)
            }
        }()

        let imageSize = CGSize(width: image.size.width / factor, height: image.size.height / factor)
        let captionHeight: CGFloat = 0
        // if let _ = image.caption {
        // TODO: Fix caption height calculations
        // }
        return (imageSize, CGSize(width: imageSize.width, height: captionHeight))
    }

    /**
     TODO: Documentation
     */
    internal static func calculateColumnWrapInset(generator: PDFGenerator, container: PDFContainer) -> (left: CGFloat, right: CGFloat) {
        guard let maxColumn = generator.columnState.getMaxColumns(for: container) else {
            return (0, 0)
        }

        var left: CGFloat = 0
        var right: CGFloat = 0

        let currentColumn = generator.columnState.getCurrentColumn(for: container)
        if currentColumn < maxColumn {
            let widths = generator.columnState.getColumnWidths(for: container)
            for i in 0..<currentColumn {
                left += widths[i]
            }
            for i in (currentColumn + 1)..<maxColumn {
                right += widths[i]
            }
        }

        return (left: left, right: right)
    }

    /**
     TODO: Documentation
     */
    internal static func calculateColumnWrapSpacing(generator: PDFGenerator, container: PDFContainer) -> (left: CGFloat, right: CGFloat) {
        guard let maxColumn = generator.columnState.getMaxColumns(for: container) else {
            return (0, 0)
        }

        var left: CGFloat = 0
        var right: CGFloat = 0

        let currentColumn = generator.columnState.getCurrentColumn(for: container)
        let columnSpacings = generator.columnState.getColumnSpacings(for: container)
        for i in 0..<currentColumn {
            left += columnSpacings[i]
        }

        if currentColumn < maxColumn - 1 {
            for i in currentColumn..<(maxColumn - 1) {
                right += columnSpacings[i]
            }
        }
        return (left: left, right: right)
    }
}
