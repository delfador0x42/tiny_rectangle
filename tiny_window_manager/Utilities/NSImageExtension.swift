//
//  NSImageExtension.swift
//  tiny_window_manager
//
//  Extension for rotating NSImage objects.
//
//  WHY ROTATION IS TRICKY:
//  When you rotate a rectangle (like an image), it takes up more space!
//  Imagine rotating a business card 45 degrees - its corners stick out further.
//  So we need to:
//    1. Calculate the new (larger) size needed to fit the rotated image
//    2. Create a new canvas of that size
//    3. Apply rotation transforms and draw the original image
//
//  WHAT ARE AFFINE TRANSFORMS?
//  Affine transforms are mathematical operations that move, scale, or rotate graphics.
//  To rotate around the CENTER of an image (not the corner), we:
//    1. Move the origin to the center
//    2. Rotate
//    3. Move the origin back
//

import Cocoa

// MARK: - NSImage Extension

extension NSImage {

    /// Creates a new image by rotating this image by the specified degrees.
    ///
    /// - Parameter degrees: The rotation angle in degrees. Positive = counter-clockwise.
    /// - Returns: A new NSImage containing the rotated version of this image.
    ///
    /// Example usage:
    /// ```
    /// let originalIcon = NSImage(named: "arrow")
    /// let rotatedIcon = originalIcon?.rotated(by: 90)  // Rotate 90 degrees
    /// ```
    ///
    /// NOTE: The returned image may be larger than the original to accommodate
    /// the rotated corners. The original image is centered in the new canvas.
    ///
    func rotated(by degrees: CGFloat) -> NSImage {
        print(#function, "called")

        // STEP 1: Calculate the new canvas size needed for the rotated image
        //
        // When you rotate a rectangle, it needs a larger bounding box.
        // We use trigonometry to calculate the exact size needed.
        //
        // First, convert degrees to radians (trigonometry functions use radians)
        let degreesInRadians = degrees * CGFloat.pi / 180.0

        // Calculate sine and cosine of the angle (we use absolute values
        // because size is always positive, regardless of rotation direction)
        let sinOfAngle = abs(sin(degreesInRadians))
        let cosOfAngle = abs(cos(degreesInRadians))

        // The new bounding box size is calculated using the rotation formula:
        // newWidth  = height * sin(angle) + width * cos(angle)
        // newHeight = width * sin(angle) + height * cos(angle)
        let newSize = CGSize(
            width: size.height * sinOfAngle + size.width * cosOfAngle,
            height: size.width * sinOfAngle + size.height * cosOfAngle
        )

        // STEP 2: Calculate where to draw the original image (centered in new canvas)
        //
        // The original image should be centered in the new larger canvas.
        // We calculate the offset needed to center it.
        let horizontalOffset = (newSize.width - size.width) / 2
        let verticalOffset = (newSize.height - size.height) / 2

        let imageBounds = NSRect(
            x: horizontalOffset,
            y: verticalOffset,
            width: size.width,
            height: size.height
        )

        // STEP 3: Set up the rotation transform
        //
        // To rotate around the CENTER (not the corner), we need three operations:
        //   1. Move origin to center of the new canvas
        //   2. Rotate
        //   3. Move origin back to corner
        //
        // These are applied in REVERSE order (that's how matrix transforms work)
        let rotationTransform = NSAffineTransform()

        // Move origin to center of new canvas
        rotationTransform.translateX(by: newSize.width / 2, yBy: newSize.height / 2)

        // Rotate around this center point
        rotationTransform.rotate(byDegrees: degrees)

        // Move origin back to bottom-left corner
        rotationTransform.translateX(by: -newSize.width / 2, yBy: -newSize.height / 2)

        // STEP 4: Create the rotated image
        //
        // lockFocus/unlockFocus creates a drawing context where we can draw
        let rotatedImage = NSImage(size: newSize)

        // Begin drawing into the new image
        rotatedImage.lockFocus()

        // Apply our rotation transform to the graphics context
        rotationTransform.concat()

        // Draw the original image (it will be rotated by the transform)
        draw(
            in: imageBounds,           // Where to draw in the destination
            from: CGRect.zero,         // Use entire source image
            operation: .copy,          // Just copy pixels (no blending)
            fraction: 1.0              // Full opacity
        )

        // Finish drawing
        rotatedImage.unlockFocus()

        return rotatedImage
    }
}
