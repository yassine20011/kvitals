import QtQuick
import QtTest
import "../../contents/ui" as UI

Item {
    id: root
    width: 640
    height: 240

    property var metrics: [
        { key: "cpu", label: "CPU", value: "42%", icon: "cpu-symbolic", color: "#ffffff" },
        { key: "ram", label: "RAM", value: "3.2 GiB", icon: "memory-symbolic", color: "#ffffff" }
    ]

    Component {
        id: viewComponent

        UI.CompactView {
            metricsModel: root.metrics
            useIcons: false
            useText: true
            effectiveFontSize: 12
            fontFamily: "Sans Serif"
            fontBold: false
            iconSize: 16
            baseTextColor: "white"
            labelColor: "white"
            iconColor: "white"
            layoutType: "horizontal"
            labelOpacity: 0.8
            separatorOpacity: 0.5
            showSeparators: true
            backgroundType: "solid"
            isPlanar: true
        }
    }

    Item {
        id: scene
        anchors.fill: parent
    }

    TestCase {
        id: testCase
        name: "CompactViewComponent"
        when: windowShown

        SignalSpy {
            id: toggleSpy
            signalName: "toggleExpanded"
        }

        property var view: null

        function init() {
            view = createTemporaryObject(viewComponent, scene);
            verify(view !== null);
            toggleSpy.target = view;
            wait(0);
        }

        function cleanup() {
            toggleSpy.clear();
            toggleSpy.target = null;
            view = null;
        }

        function test_horizontalAndVerticalSizing() {
            verify(view.implicitWidth > 0);
            verify(view.implicitHeight > 0);
            verify(!view.isVertical);

            view.layoutType = "vertical";
            verify(view.isVertical);
            verify(view.implicitWidth > 0);
            verify(view.implicitHeight > 0);
        }

        function test_planarBackgroundPadding() {
            verify(view.hPadding > 0);
            verify(view.vPadding > 0);

            view.backgroundType = "transparent";
            compare(view.hPadding, 0);
            compare(view.vPadding, 0);
        }

        function test_pointerInteractionEmitsExpansionSignal() {
            view.width = Math.max(100, view.implicitWidth);
            view.height = Math.max(40, view.implicitHeight);
            mouseClick(view, view.width / 2, view.height / 2, Qt.LeftButton);
            compare(toggleSpy.count, 1);
        }
    }
}
