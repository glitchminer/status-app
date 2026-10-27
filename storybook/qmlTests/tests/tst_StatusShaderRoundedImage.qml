import QtQuick
import QtTest

import StatusQ.Components

Item {
    id: root

    width: 200
    height: 200

    // solid red, 64 x 32
    readonly property url redImage: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAWElEQVR4nO3QMREAMBDDsPAn/YWhoR60+7zb7mfTAVoDdIDWAB2gNUAHaA3QAVoDdIDWAB2gNUAHaA3QAVoDdIDWAB2gNUAHaA3QAVoDdIDWAB2gNUAHaA8g8vDiJft7OwAAAABJRU5ErkJggg=="

    Component {
        id: imageComponent

        StatusShaderRoundedImage {
            width: 64
            height: 64
            source: root.redImage
            asynchronous: false
        }
    }

    TestCase {
        name: "StatusShaderRoundedImage"
        when: windowShown

        readonly property bool software: root.GraphicsInfo.api === GraphicsInfo.Software

        function createImage(properties) {
            const image = createTemporaryObject(imageComponent, root, properties)
            verify(!!image)
            tryCompare(image, "status", Image.Ready)
            return image
        }

        // Grabbing renders the window, so the pixels are the shader's.
        function grab(image) {
            if (software)
                skip("ShaderEffect does not run under the software renderer")
            return grabImage(image)
        }

        function isRed(color) {
            return color.r > 0.9 && color.g < 0.1 && color.b < 0.1
        }

        function test_cornersAreRoundedAndTheRestIsDrawn() {
            const img = grab(createImage({ radius: 16 }))

            verify(!isRed(img.pixel(1, 1)), "top-left corner is cut")
            verify(!isRed(img.pixel(62, 1)), "top-right corner is cut")
            verify(!isRed(img.pixel(1, 62)), "bottom-left corner is cut")
            verify(!isRed(img.pixel(62, 62)), "bottom-right corner is cut")
            verify(isRed(img.pixel(32, 32)), "centre is drawn")
            verify(isRed(img.pixel(32, 1)), "straight edge is drawn")
            verify(isRed(img.pixel(1, 32)), "straight edge is drawn")
        }

        function test_eachCornerHasItsOwnRadius() {
            const img = grab(createImage({ radius: 16, bottomLeftRadius: 0 }))

            verify(isRed(img.pixel(1, 62)), "square bottom-left corner is drawn")
            verify(!isRed(img.pixel(62, 62)), "bottom-right corner is still cut")
        }

        function test_radiusIsClampedToHalfTheShorterSide() {
            // 64 x 32: a radius of 1000 behaves as 16, a stadium shape
            const img = grab(createImage({ height: 32, radius: 1000 }))

            verify(isRed(img.pixel(1, 16)), "left end is a half circle, not empty")
            verify(isRed(img.pixel(32, 1)), "straight top edge is drawn")
            verify(!isRed(img.pixel(1, 1)), "corner is cut")
        }

        function test_fitRoundsTheLetterboxedImage() {
            // a 2:1 image in a square item: painted 64 x 32, centred
            const image = createImage({ fillMode: Image.PreserveAspectFit, radius: 8 })

            compare(image.paintedWidth, 64)
            compare(image.paintedHeight, 32)
            compare(image.contentRect.y, 16)

            const img = grab(image)

            verify(!isRed(img.pixel(32, 8)), "letterbox stays empty")
            verify(isRed(img.pixel(32, 32)), "image is drawn")
            verify(!isRed(img.pixel(1, 17)), "corner of the painted image is cut")
            verify(isRed(img.pixel(1, 32)), "side of the painted image is drawn")
        }

        function test_animatedSourceBuildsAnAnimatedImage() {
            const image = createImage({ animated: true,
                                        source: Qt.resolvedUrl("../../testData/image_example.gif") })

            verify(image.image instanceof AnimatedImage)
            compare(image.image.playing, true)

            image.playing = false
            compare(image.image.playing, false)
        }

        function test_stillSourceBuildsAnImage() {
            const image = createImage({})

            verify(!(image.image instanceof AnimatedImage))
        }

        function test_zeroSourceSizeDecodesAtNativeSize_data() {
            return [
                { tag: "still", animated: false, source: root.redImage, size: Qt.size(64, 32) },
                { tag: "animated", animated: true,
                  source: Qt.resolvedUrl("../../testData/image_example_animated.gif"), size: Qt.size(320, 180) }
            ]
        }

        function test_zeroSourceSizeDecodesAtNativeSize(data) {
            const image = createImage({ animated: data.animated, source: data.source,
                                        width: 40, height: 40, sourceSize: Qt.size(0, 0) })

            compare(image.image.implicitWidth, data.size.width)
            compare(image.image.implicitHeight, data.size.height)
        }

        // Decoded by StatusImage's RenderSizedImage, whose own tests check
        // the decode size (never upscaled, stepped, capped); only it has
        // explicitlySized.
        function test_unsetSourceSizeDecodesAsStatusImage() {
            const image = createImage({})

            verify("explicitlySized" in image.image)
        }

        function test_explicitSourceSizeIsInPixels() {
            const image = createImage({ sourceSize: Qt.size(16, 8) })

            verify(!("explicitlySized" in image.image))
            compare(image.image.implicitWidth, 16)
            compare(image.image.implicitHeight, 8)
        }

        function test_cutoutCutsACircle() {
            // a circle centred on the right edge, as for an overlapping icon
            const img = grab(createImage({ cutoutCenter: Qt.point(64, 32), cutoutRadius: 20 }))

            verify(!isRed(img.pixel(60, 32)), "inside the circle is cut")
            verify(!isRed(img.pixel(50, 32)), "inside the circle is cut")
            verify(isRed(img.pixel(40, 32)), "outside the circle is drawn")
            verify(isRed(img.pixel(62, 2)), "the corner outside the circle is drawn")
        }

        function test_softwareRendererShowsTheImageUnrounded() {
            if (!software)
                skip("software renderer only")

            const image = createImage({ radius: 16 })

            verify(image.image.visible)
            compare(image.image.width, image.width)
            compare(image.image.height, image.height)
        }
    }
}
