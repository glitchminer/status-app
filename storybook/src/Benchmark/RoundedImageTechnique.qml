import QtQuick
import QtQuick.Effects

import StatusQ.Components

/*
  One image with rounded corners, drawn with the chosen technique:

    plain    an Image with no rounding - the floor the others are measured
             against
    layer    the image rendered into a layer, a mask into a second one, and
             a MultiEffect combining them - what chat images did
             (StatusImageMessage, StatusChatImageLoader)
    avatar   StatusRoundedImage - the same layer + mask, on the component's
             root, as avatars use it (StatusSmartIdenticon); stills only
    shader   StatusShaderRoundedImage - one ShaderEffect sampling the image's
             own texture
*/
Loader {
    id: root

    property string technique: "shader"
    property url source
    property bool animated: false
    property int fillMode: Image.PreserveAspectCrop
    // Decode size, in pixels.
    property size sourceSize
    property real radius: 16
    // half the size, as avatars are; overrides radius and tailRadius
    property bool circular: false
    // the chat bubble's tail: the bottom-left corner
    property real tailRadius: radius

    readonly property real cornerRadius: circular ? Math.min(width, height) / 2 : radius
    readonly property real bottomLeftRadius: circular ? cornerRadius : Math.min(tailRadius, cornerRadius)

    readonly property int status: item ? item.status : Image.Null

    sourceComponent: {
        switch (technique) {
        case "plain": return plainComponent
        case "layer": return layerComponent
        case "avatar": return avatarComponent
        case "shader": return shaderComponent
        }
        return null
    }

    // an Image, or an AnimatedImage for animated sources
    component PlainImage: Loader {
        id: plainImage

        readonly property int status: item ? item.status : Image.Null
        readonly property real paintedWidth: item ? item.paintedWidth : 0
        readonly property real paintedHeight: item ? item.paintedHeight : 0

        sourceComponent: root.animated ? animatedImage : stillImage

        Component {
            id: stillImage

            Image {
                source: root.source
                sourceSize: root.sourceSize
                fillMode: root.fillMode
                asynchronous: true
            }
        }

        Component {
            id: animatedImage

            AnimatedImage {
                source: root.source
                sourceSize: root.sourceSize
                fillMode: root.fillMode
                asynchronous: true
            }
        }
    }

    Component {
        id: plainComponent

        PlainImage {}
    }

    Component {
        id: layerComponent

        Item {
            id: layered

            readonly property int status: image.status

            Item {
                id: box

                anchors.centerIn: parent
                width: root.fillMode === Image.PreserveAspectCrop ? layered.width : image.paintedWidth
                height: root.fillMode === Image.PreserveAspectCrop ? layered.height : image.paintedHeight

                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                    maskSource: Rectangle {
                        parent: layered
                        width: box.width
                        height: box.height
                        visible: false
                        layer.enabled: true

                        topLeftRadius: root.cornerRadius
                        topRightRadius: root.cornerRadius
                        bottomRightRadius: root.cornerRadius
                        bottomLeftRadius: root.bottomLeftRadius
                    }
                }

                PlainImage {
                    id: image

                    anchors.centerIn: parent
                    width: layered.width
                    height: layered.height
                }
            }
        }
    }

    Component {
        id: avatarComponent

        // as StatusSmartIdenticon builds it; one radius, so no tail
        StatusRoundedImage {
            readonly property int status: image.status

            radius: root.cornerRadius
            image.source: root.source
            image.fillMode: root.fillMode
            // as the others: StatusImage is synchronous by default, which
            // decodes a local file on the GUI thread
            image.asynchronous: true
            // StatusImage takes logical pixels and decodes for the device
            // pixel ratio itself
            image.sourceSize: Qt.size(root.sourceSize.width / d.dpr, root.sourceSize.height / d.dpr)
        }
    }

    Component {
        id: shaderComponent

        StatusShaderRoundedImage {
            source: root.source
            animated: root.animated
            fillMode: root.fillMode
            sourceSize: root.sourceSize
            radius: root.cornerRadius
            bottomLeftRadius: root.bottomLeftRadius
        }
    }

    QtObject {
        id: d

        readonly property real dpr: root.Window.window ? root.Window.window.devicePixelRatio : 1
    }
}
