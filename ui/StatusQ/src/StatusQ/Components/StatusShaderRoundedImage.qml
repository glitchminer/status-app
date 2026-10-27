import QtQuick

import StatusQ.Components.private

/*!
   \qmltype StatusShaderRoundedImage
   \inherits Item
   \inqmlmodule StatusQ.Components
   \since StatusQ.Components 0.1
   \brief An image with rounded corners, drawn in a single pass.

   One ShaderEffect samples the image's own texture and computes each
   fragment's coverage from its distance to the rounded rectangle, so the
   corners take no offscreen layer, no mask texture and no extra pass - unlike
   rounding an Image through \c layer.enabled and a MultiEffect mask. Each
   corner has its own radius. Atlas textures are sampled in place, not copied.

   The image itself is a hidden texture source, exposed as \l image for its
   status, progress and implicit size. For a still image an Image is built,
   for an animated one an AnimatedImage.

   With PreserveAspectFit the corners follow the letterboxed image, not the
   item.

   Qt Quick's software renderer cannot run shaders: there the image is shown
   as it is, without rounded corners.

   \qml
        StatusShaderRoundedImage {
            width: 144
            height: 144
            source: "photo.jpg"
            radius: 16
            bottomLeftRadius: 4
        }
   \endqml
*/
Item {
    id: root

    property url source
    // Builds an AnimatedImage rather than an Image.
    property bool animated: false
    property bool playing: true

    // Image.PreserveAspectCrop fills the item, Image.PreserveAspectFit
    // letterboxes; the corners follow what is painted.
    property int fillMode: Image.PreserveAspectCrop

    property bool cache: true
    property bool asynchronous: true
    property bool smooth: true

    // Decode size, in pixels. Unset, a still image is decoded as StatusImage
    // decodes it: for the rendered size, never above the source's native
    // size, and kept while resized within a step; an animated one for the
    // rendered size. Qt.size(0, 0) decodes at the source's native size.
    property size sourceSize: Qt.size(-1, -1)

    property real radius: 0
    property real topLeftRadius: radius
    property real topRightRadius: radius
    property real bottomLeftRadius: radius
    property real bottomRightRadius: radius

    // Circle cut out - where an overlapping icon or badge sits - in this
    // item's coordinates; a radius of 0 cuts nothing.
    property point cutoutCenter
    property real cutoutRadius: 0

    // The hidden Image (or AnimatedImage) the shader samples.
    readonly property Image image: imageLoader.item
    readonly property int status: image ? image.status : Image.Null

    // The painted part of the image, in this item's coordinates: the item
    // itself when cropping, the letterboxed image otherwise.
    readonly property rect contentRect: fillMode === Image.PreserveAspectCrop
                                        ? Qt.rect(0, 0, width, height)
                                        : d.imageRect
    readonly property real paintedWidth: contentRect.width
    readonly property real paintedHeight: contentRect.height

    QtObject {
        id: d

        readonly property real dpr: root.Window.window ? root.Window.window.devicePixelRatio
                                                       : Screen.devicePixelRatio
        readonly property bool software: root.GraphicsInfo.api === GraphicsInfo.Software
        readonly property bool renderSized: root.sourceSize.width < 0 && root.sourceSize.height < 0
        // An AnimatedImage scales to a 0 x 0 sourceSize instead of ignoring
        // it: the images get it reset (undefined) instead.
        readonly property bool nativeSize: !renderSized && root.sourceSize.width <= 0
                                           && root.sourceSize.height <= 0
        // In pixels, for the animated image, which is not render sized
        readonly property size renderedSize: root.fillMode === Image.PreserveAspectCrop
                                             ? Qt.size(Math.ceil(root.width * dpr), Math.ceil(root.height * dpr))
                                             : Qt.size(Math.ceil(root.width * dpr), 0)

        // Decoded size in pixels. Equal to the implicit size for raster
        // sources without an "@Nx" suffix; only its aspect ratio is used.
        readonly property size textureSize: root.image
                                            ? Qt.size(root.image.implicitWidth, root.image.implicitHeight)
                                            : Qt.size(0, 0)

        // The whole image, scaled and centered per fillMode, in the item's
        // coordinates. Larger than the item when cropping.
        readonly property rect imageRect: {
            const tw = textureSize.width
            const th = textureSize.height

            if (tw <= 0 || th <= 0 || root.width <= 0 || root.height <= 0)
                return Qt.rect(0, 0, 0, 0)

            const scale = root.fillMode === Image.PreserveAspectCrop
                        ? Math.max(root.width / tw, root.height / th)
                        : Math.min(root.width / tw, root.height / th)
            const w = tw * scale
            const h = th * scale

            return Qt.rect((root.width - w) / 2, (root.height - h) / 2, w, h)
        }

        function clampRadius(r) {
            return Math.max(0, Math.min(r, root.contentRect.width / 2, root.contentRect.height / 2))
        }
    }

    Loader {
        id: imageLoader

        sourceComponent: {
            if (root.animated)
                return animatedImage
            return d.renderSized ? renderSizedImage : stillImage
        }
    }

    // A texture source only: zero-sized and hidden, so it builds no paint
    // node of its own - except under the software renderer, which draws it.
    Component {
        id: stillImage

        Image {
            width: d.software ? root.width : 0
            height: d.software ? root.height : 0
            visible: d.software

            source: root.source
            sourceSize: d.nativeSize ? undefined : root.sourceSize
            fillMode: root.fillMode
            asynchronous: root.asynchronous
            cache: root.cache
            smooth: root.smooth
        }
    }

    // Its sourceSize is logical: it scales it by the device pixel ratio
    // itself.
    Component {
        id: renderSizedImage

        RenderSizedImage {
            width: d.software ? root.width : 0
            height: d.software ? root.height : 0
            visible: d.software

            source: root.source
            sourceSize: Qt.size(Math.ceil(root.width), Math.ceil(root.height))
            fillMode: root.fillMode
            asynchronous: root.asynchronous
            cache: root.cache
            smooth: root.smooth
        }
    }

    Component {
        id: animatedImage

        AnimatedImage {
            width: d.software ? root.width : 0
            height: d.software ? root.height : 0
            visible: d.software

            source: root.source
            sourceSize: {
                if (d.renderSized)
                    return d.renderedSize
                return d.nativeSize ? undefined : root.sourceSize
            }
            fillMode: root.fillMode
            asynchronous: root.asynchronous
            cache: root.cache
            smooth: root.smooth
            playing: root.playing
        }
    }

    ShaderEffect {
        x: root.contentRect.x
        y: root.contentRect.y
        width: root.contentRect.width
        height: root.contentRect.height

        visible: !d.software && root.status === Image.Ready

        property Item source: root.image
        property size itemSize: Qt.size(width, height)
        property vector4d radii: Qt.vector4d(d.clampRadius(root.topLeftRadius),
                                             d.clampRadius(root.topRightRadius),
                                             d.clampRadius(root.bottomRightRadius),
                                             d.clampRadius(root.bottomLeftRadius))
        // the painted part of the image, as a 0..1 window into it
        property vector4d uvTransform: {
            const cr = root.contentRect
            const ir = d.imageRect

            if (ir.width <= 0 || ir.height <= 0)
                return Qt.vector4d(0, 0, 1, 1)

            return Qt.vector4d((cr.x - ir.x) / ir.width, (cr.y - ir.y) / ir.height,
                               cr.width / ir.width, cr.height / ir.height)
        }
        property real edgeWidth: 1 / d.dpr
        // in the shader item's coordinates, which start at contentRect
        property vector3d cutout: Qt.vector3d(root.cutoutCenter.x - root.contentRect.x,
                                              root.cutoutCenter.y - root.contentRect.y,
                                              root.cutoutRadius)

        fragmentShader: "qrc:/StatusQ/shaders/roundedimage.frag.qsb"
    }
}
