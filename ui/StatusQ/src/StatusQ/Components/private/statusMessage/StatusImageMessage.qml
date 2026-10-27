import QtQuick

import StatusQ.Components
import StatusQ.Core
import StatusQ.Core.Theme

Item {
    id: imageContainer

    enum ShapeType {
        ROUNDED = 0,
        LEFT_ROUNDED = 1,
        RIGHT_ROUNDED = 2
    }

    // The rounded image (StatusShaderRoundedImage), built asynchronously.
    // Stills decode at a bounded size (an album can hold dozens of photos and
    // a full decode of each exhausts memory).
    readonly property Item imageAlias: imageLoader.item

    property bool isAppWindowActive: false
    property url source: ""
    property bool allCornersRounded: false
    property bool isLeftCorner: true
    property int imageWidth: 350
    property int shapeType: -1

    // Switches scaling mode:
    // - false (default): PreserveAspectFit → full image visible, may letterbox.
    // - true: PreserveAspectCrop → fills container, may crop edges.
    property bool isFillCropMode: false

    // Determines whether album images respond to user click.
    // - true (default): images are clickable; TapHandlers emit `clicked` on tap.
    // - false: images are display-only with no interaction.
    property bool imageClickable: true

    // Cursor shape used when hovering over clickable album images.
    // - Default: Qt.PointingHandCursor (hand icon).
    // - Common alternatives: Qt.ArrowCursor, Qt.CrossCursor, etc.
    property int imageCursorShape: Qt.PointingHandCursor

    property string loadingImageText: ""
    property string errorLoadingImageText: ""

    signal clicked(var image, var mouse, var imageSource, point pos)

    implicitWidth: imageBox.width
    implicitHeight: imageBox.height

    QtObject {
        id: _internal
        readonly property bool isAnimated: !!source && source.toString().endsWith('.gif')
        readonly property int imageStatus: imageContainer.imageAlias ? imageContainer.imageAlias.status : Image.Loading
        // Decode width in 128px steps so a layout-driven imageWidth (albums on
        // narrow screens, rotation) doesn't re-decode every visible image.
        readonly property int decodeWidth: Math.ceil(imageContainer.imageWidth * Screen.devicePixelRatio / 128) * 128
        // Crop mode fills a square box, so bound both sides or landscape
        // photos decode too short and get upscaled.
        readonly property int decodeHeight: imageContainer.isFillCropMode ? decodeWidth : 0
        property bool pausePlaying: false

        // The box for a decoded image of implicit size iw x ih, shown at
        // width w: square for crop, the image's aspect ratio for fit.
        function boxHeight(w, iw, ih) {
            if (imageContainer.isFillCropMode)
                return w // Fixed box for crop
            if (iw > 0)
                return Math.round(w * ih / iw) // Fit by width / Preserve aspect ratio
            return ih // Before image is loaded
        }
    }

    Item {
        id: imageBox

        width: imageContainer.imageAlias ? imageContainer.imageAlias.width : 0
        height: imageContainer.imageAlias ? imageContainer.imageAlias.height : 0

        Loader {
            id: imageLoader
            asynchronous: true
            sourceComponent: roundedImageComponent
        }

        HoverHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad | PointerDevice.Stylus
            enabled: imageContainer.imageClickable
            cursorShape: imageContainer.imageCursorShape
        }

        TapHandler {
            gesturePolicy: TapHandler.ReleaseWithinBounds
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            enabled: imageContainer.imageClickable
            onTapped: (eventPoint, button) => {
                if (_internal.isAnimated && button === Qt.LeftButton) {
                    // FIXME the ListView completely removes Items that scroll out of view
                    // so when we scroll backto the image, it gets reloaded and playing is reset
                    _internal.pausePlaying = !_internal.pausePlaying
                    return
                }
                imageContainer.clicked(imageContainer.imageAlias, { button }, imageContainer.source, eventPoint.position)
            }
            onLongPressed: {
                if (point.device.type !== PointerDevice.TouchScreen)
                    return
                imageContainer.clicked(imageContainer.imageAlias, { button: Qt.RightButton }, imageContainer.source, point.position)
            }
        }
    }

    // Rounded in one shader pass over the image's own texture; the bubble's
    // tail is the small corner. Only the needed kind of image is built
    // inside: gifs need AnimatedImage, which cannot bound its decode.
    Component {
        id: roundedImageComponent

        StatusShaderRoundedImage {
            id: imageMessage

            readonly property real decodedWidth: image ? image.implicitWidth : 0
            readonly property real decodedHeight: image ? image.implicitHeight : 0

            width: Math.min(decodedWidth, imageContainer.imageWidth)
            height: _internal.boxHeight(width, decodedWidth, decodedHeight)

            radius: 16
            bottomLeftRadius: imageContainer.shapeType === StatusImageMessage.ShapeType.LEFT_ROUNDED ? 4 : 16
            bottomRightRadius: imageContainer.shapeType === StatusImageMessage.ShapeType.RIGHT_ROUNDED ? 4 : 16

            animated: _internal.isAnimated
            playing: imageContainer.isAppWindowActive && !_internal.pausePlaying
            fillMode: imageContainer.isFillCropMode ? Image.PreserveAspectCrop : Image.PreserveAspectFit
            sourceSize: Qt.size(_internal.decodeWidth, _internal.decodeHeight)
            source: imageContainer.source
            cache: false
        }
    }

    Rectangle {
        id: loadingImage
        visible: _internal.imageStatus === Image.Loading || _internal.imageStatus === Image.Error
        width: parent.width
        height: width
        border.width: 1
        border.color: Theme.palette.baseColor2
        radius: 8

        StatusBaseText {
            anchors.centerIn: parent
            text: _internal.imageStatus === Image.Error ? errorLoadingImageText: loadingImageText
            color: _internal.imageStatus === Image.Error?
                       Theme.palette.dangerColor1 :
                       Theme.palette.directColor1
            font.pixelSize: Theme.primaryTextFontSize
        }
    }
}
