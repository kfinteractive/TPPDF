//
//  PDFPageLayout.swift
//  TPPDF
//
//  Created by Philip Niedertscheider on 11/08/2017.
//
import UIKit

/**
 Contains all relevant layout informations of a pdf document
 */
public struct PDFPageLayout: PDFJSONSerializable {

    // MARK: - PUBLIC VARS

    /**
     Size of each page
     */
    public var size: CGSize = CGSize.zero

    /**
     Margins of each page.

     `header`: Top inset of page
     `footer`: Bottom inset of page
     `left`: Left inset of page
     `right`: Right inset of page
     */
    public var margin: UIEdgeInsets = .zero

    /**
     Spaces between header, content and footer.

     `header`: Space between header and content
     `footer`: Space between content and footer
     */
    public var space: (header: CGFloat, footer: CGFloat)

    // MARK: - PUBLIC FUNCTIONS

    /**
     Creates a new layout object using the given parameters.

     - Parameter size: Size of the page
     - Parameter margin: Edge margin insets
     - Parameter space: Vertical spacing between header, footer and content
     */
    public init(size: CGSize = .zero, margin: UIEdgeInsets = .zero, space: (header: CGFloat, footer: CGFloat) = (0, 0)) {
        self.size = size
        self.margin = margin
        self.space = space
    }

    // MARK: - INTERNAL COMPUTED VARS

    /**
     Returns a `CGRect` with a origin at zero and the `size` of the layout.
     */
    public var bounds: CGRect {
        return CGRect(origin: .zero, size: size)
    }

    /**
     Shorthand access to layout width
     */
    public var width: CGFloat {
        return size.width
    }

    /**
     Shorthand access to layout height
     */
    public var height: CGFloat {
        return size.height
    }
}
