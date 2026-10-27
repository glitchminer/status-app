import QtQuick
import QtTest

import StatusQ.Components

import Benchmark

/*
  StatusShaderRoundedImage decoding for its rendered size (sourceSize not
  set), with a 320 x 180 source: 100 images.

  Variants:
  - small: 144 x 144 cells, the source scaled down (static, scroll, resize)
  - banner: 324 x 170 cells - a link preview's banner - the source smaller
    than the decode at 2x (static, scroll, resize)
*/
Item {
    id: root

    width: 1000
    height: 800

    readonly property url stillSource: Qt.resolvedUrl("../../testData/image_example.png")

    BenchmarkRunner {
        id: runner

        anchors.fill: parent
        count: 100

        delegate: StatusShaderRoundedImage {
            required property int index

            width: runner.cellWidth * runner.sizeFactor
            height: runner.cellHeight * runner.sizeFactor
            radius: 16
            // a distinct pixmap per cell; the query only keys the pixmap
            // cache
            source: `${root.stillSource}?cell=${index}`
        }
    }

    TestCase {
        name: "Bench"
        when: windowShown

        function bench(width, height) {
            runner.cellWidth = width
            runner.cellHeight = height
            runner.scenarios = ["static", "scroll", "resize"]
            runner.start()
            tryVerify(() => runner.result !== null, 300000)
            console.info("BENCH-RESULT " + JSON.stringify(runner.result))
        }

        function test_small() { bench(144, 144) }
        function test_banner() { bench(324, 170) }
    }
}
