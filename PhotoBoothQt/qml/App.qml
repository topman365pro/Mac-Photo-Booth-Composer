import QtQuick
import QtQuick.Controls
import PhotoBooth

ApplicationWindow {
    id: window
    width: 1440
    height: 940
    visible: true
    title: "PhotoBooth"
    color: "#f4f1ea"

    MainScreen {
        anchors.fill: parent
        controller: appController
    }
}
