import QtCore
import QtMultimedia
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import PhotoBooth

Item {
    id: root

    required property var controller
    property var document: controller.document
    property int selectedCameraIndex: 0

    function updateSelectedCamera(index) {
        if (index < 0 || index >= mediaDevices.videoInputs.length) {
            return
        }

        const device = mediaDevices.videoInputs[index]
        selectedCameraIndex = index
        camera.cameraDevice = device
        document.selectedCameraId = device.id
        const torchSupported = camera.isTorchModeSupported(Camera.TorchOn)
        document.torchSupported = torchSupported
        if (!torchSupported) {
            document.torchEnabled = false
            camera.torchMode = Camera.TorchOff
        }
    }

    function chooseConfiguredCamera() {
        if (mediaDevices.videoInputs.length === 0) {
            document.cameraStatus = "No camera detected"
            return
        }

        for (let i = 0; i < mediaDevices.videoInputs.length; ++i) {
            if (mediaDevices.videoInputs[i].id === document.selectedCameraId) {
                updateSelectedCamera(i)
                return
            }
        }

        updateSelectedCamera(0)
    }

    MediaDevices {
        id: mediaDevices
    }

    Camera {
        id: camera
        onErrorOccurred: document.cameraStatus = errorString
    }

    ImageCapture {
        id: imageCapture
        onErrorOccurred: (_, errorString) => document.cameraStatus = errorString
        onImageSaved: (requestId, fileName) => {
            if (document.setSlotImageFromSource(document.activeSlot, fileName)) {
                document.activeSlot = document.nextRecommendedSlot()
            }
        }
    }

    CaptureSession {
        id: captureSession
        camera: camera
        imageCapture: imageCapture
        videoOutput: videoOutput
    }

    FileDialog {
        id: backgroundDialog
        title: "Choose a background image"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp)"]
        onAccepted: document.setBackgroundImageFromSource(selectedFile.toString())
    }

    FileDialog {
        id: exportDialog
        title: "Export A4 PDF"
        fileMode: FileDialog.SaveFile
        defaultSuffix: "pdf"
        currentFile: "PhotoBooth-A4.pdf"
        nameFilters: ["PDF files (*.pdf)"]
        onAccepted: controller.exportPdf(selectedFile.toString())
    }

    Component.onCompleted: {
        chooseConfiguredCamera()
        if (mediaDevices.videoInputs.length > 0) {
            camera.start()
        }
    }

    Connections {
        target: mediaDevices
        function onVideoInputsChanged() {
            chooseConfiguredCamera()
            if (mediaDevices.videoInputs.length > 0) {
                camera.start()
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#f4f1ea"
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        Frame {
            Layout.fillHeight: true
            Layout.preferredWidth: 320
            padding: 16
            background: Rectangle {
                color: "#fffaf2"
                radius: 18
                border.color: "#ded3c0"
            }

            ScrollView {
                anchors.fill: parent
                contentWidth: availableWidth
                clip: true

                ColumnLayout {
                    width: parent.width
                    spacing: 18

                    Label {
                        text: "Photo Booth Builder"
                        font.pixelSize: 28
                        font.bold: true
                    }

                    Label {
                        text: "1) Snap 3 photos  2) Tune the strip  3) Export A4 PDF"
                        color: "#6f6557"
                        wrapMode: Text.WordWrap
                    }

                    GroupBox {
                        Layout.fillWidth: true
                        title: "Camera"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 10

                            ComboBox {
                                Layout.fillWidth: true
                                model: mediaDevices.videoInputs
                                textRole: "description"
                                currentIndex: selectedCameraIndex
                                onActivated: updateSelectedCamera(index)
                            }

                            Switch {
                                text: "Torch"
                                enabled: document.torchSupported
                                checked: document.torchEnabled
                                onToggled: {
                                    document.torchEnabled = checked
                                    camera.torchMode = checked ? Camera.TorchOn : Camera.TorchOff
                                }
                            }

                            Label {
                                text: document.cameraStatus
                                color: "#7a6d5b"
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    GroupBox {
                        Layout.fillWidth: true
                        title: "Collage Settings"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 10

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                columnSpacing: 12
                                rowSpacing: 8

                                Label { text: "Spacing" }
                                Slider { value: document.spacing; from: 0; to: 600; onMoved: document.spacing = value }

                                Label { text: "Photo Size" }
                                Slider { value: document.photoScale; from: 0.5; to: 1.0; onMoved: document.photoScale = value }

                                Label { text: "Top Margin" }
                                Slider { value: document.insetTop; from: 0; to: 600; onMoved: document.insetTop = value }

                                Label { text: "Left Margin" }
                                Slider { value: document.insetLeft; from: 0; to: 600; onMoved: document.insetLeft = value }

                                Label { text: "Right Margin" }
                                Slider { value: document.insetRight; from: 0; to: 600; onMoved: document.insetRight = value }

                                Label { text: "Corner Radius" }
                                Slider { value: document.cornerRadius; from: 0; to: 80; onMoved: document.cornerRadius = value }

                                Label { text: "Border Width" }
                                Slider {
                                    value: document.borderWidth
                                    from: 0.5
                                    to: 20
                                    enabled: document.drawBorder
                                    onMoved: document.borderWidth = value
                                }

                                Label { text: "Bottom Extra" }
                                Slider { value: document.bottomMarginExtra; from: 0; to: 600; onMoved: document.bottomMarginExtra = value }

                                Label { text: "Strip Length" }
                                Slider { value: document.stripLengthFactor; from: 0.6; to: 2.5; onMoved: document.stripLengthFactor = value }

                                Label { text: "PDF Width" }
                                Slider { value: document.collageWidthFraction; from: 0.1; to: 1.0; onMoved: document.collageWidthFraction = value }
                            }

                            CheckBox {
                                text: "Border"
                                checked: document.drawBorder
                                onToggled: document.drawBorder = checked
                            }

                            CheckBox {
                                text: "Mirror Photos"
                                checked: document.mirrorPhotos
                                onToggled: document.mirrorPhotos = checked
                            }
                        }
                    }

                    GroupBox {
                        Layout.fillWidth: true
                        title: "Background"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 10

                            RowLayout {
                                Layout.fillWidth: true

                                Button {
                                    text: "Choose Background"
                                    onClicked: backgroundDialog.open()
                                }

                                Button {
                                    text: "Clear"
                                    enabled: document.backgroundImageUrl.toString().length > 0
                                    onClicked: document.clearBackgroundImage()
                                }
                            }

                            Image {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 100
                                visible: document.backgroundImageUrl.toString().length > 0
                                source: document.backgroundImageUrl
                                fillMode: Image.PreserveAspectFit
                            }
                        }
                    }

                    GroupBox {
                        Layout.fillWidth: true
                        title: "Export"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 10

                            Button {
                                text: "Export A4 PDF"
                                enabled: document.readyToExport
                                onClicked: exportDialog.open()
                            }

                            Label {
                                text: controller.exportMessage
                                visible: text.length > 0
                                color: "#6f6557"
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 360
                spacing: 16

                Frame {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    padding: 12
                    background: Rectangle {
                        color: "#161616"
                        radius: 20
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 12

                        VideoOutput {
                            id: videoOutput
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            fillMode: VideoOutput.PreserveAspectCrop
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            Button {
                                text: "Snap"
                                enabled: imageCapture.readyForCapture
                                onClicked: {
                                    const tempPath = StandardPaths.writableLocation(StandardPaths.TempLocation)
                                                     + "/photobooth-" + Date.now() + ".jpg"
                                    imageCapture.captureToFile(tempPath)
                                }
                            }

                            Button {
                                text: "Clear Slot"
                                enabled: document.hasSlotImage(document.activeSlot)
                                onClicked: document.clearSlot(document.activeSlot)
                            }

                            Label {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignRight
                                color: "#f3ebdb"
                                text: imageCapture.readyForCapture ? "" : "Camera starting or unavailable"
                            }
                        }
                    }
                }

                Frame {
                    Layout.preferredWidth: 240
                    Layout.fillHeight: true
                    padding: 12
                    background: Rectangle {
                        color: "#fffaf2"
                        radius: 20
                        border.color: "#ded3c0"
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 10

                        Label {
                            text: "Filmstrip"
                            font.pixelSize: 20
                            font.bold: true
                        }

                        Repeater {
                            model: 3
                            delegate: Button {
                                required property int index
                                Layout.fillWidth: true
                                Layout.preferredHeight: 100
                                padding: 0
                                onClicked: document.activeSlot = index

                                background: Rectangle {
                                    radius: 12
                                    color: document.hasSlotImage(index) ? "#000000" : "#ece6dc"
                                    border.width: document.activeSlot === index ? 3 : 1
                                    border.color: document.activeSlot === index ? "#d86d1d" : "#cabda7"
                                }

                                contentItem: Item {
                                    anchors.fill: parent

                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: 2
                                        visible: document.hasSlotImage(index)
                                        source: document.slotSource(index)
                                        fillMode: Image.PreserveAspectCrop
                                        clip: true
                                    }

                                    Label {
                                        anchors.centerIn: parent
                                        visible: !document.hasSlotImage(index)
                                        text: "Slot " + (index + 1)
                                        color: "#6f6557"
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }

            Frame {
                Layout.fillWidth: true
                Layout.fillHeight: true
                padding: 12
                background: Rectangle {
                    color: "#fffaf2"
                    radius: 20
                    border.color: "#ded3c0"
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10

                    Label {
                        text: "Collage Preview"
                        font.pixelSize: 22
                        font.bold: true
                    }

                    CollagePreview {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        document: root.document
                    }
                }
            }
        }
    }
}
