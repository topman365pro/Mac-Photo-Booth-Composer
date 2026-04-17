cmake_minimum_required(VERSION 3.21)

project(PhotoBoothQt VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS
    Core
    Gui
    Qml
    Quick
    QuickControls2
    QuickDialogs2
    Multimedia
    Test
)

qt_standard_project_setup(REQUIRES 6.5)

configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/Info.plist.in
    ${CMAKE_CURRENT_BINARY_DIR}/Info.plist
    @ONLY
)

qt_add_executable(PhotoBoothQt
    src/main.cpp
    src/AppController.cpp
    src/AppController.h
    src/CollageDocument.cpp
    src/CollageDocument.h
    src/CollagePreviewItem.cpp
    src/CollagePreviewItem.h
    src/CollageRenderer.cpp
    src/CollageRenderer.h
    src/PdfExporter.cpp
    src/PdfExporter.h
)

qt_add_qml_module(PhotoBoothQt
    URI PhotoBooth
    VERSION 1.0
    QML_FILES
        qml/App.qml
        qml/MainScreen.qml
)

target_link_libraries(PhotoBoothQt PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::QuickDialogs2
    Qt6::Multimedia
)

set_target_properties(PhotoBoothQt PROPERTIES
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_BUNDLE_NAME "PhotoBooth"
    MACOSX_BUNDLE_GUI_IDENTIFIER "com.photobooth.qt"
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_BINARY_DIR}/Info.plist"
    WIN32_EXECUTABLE TRUE
)

qt_generate_deploy_qml_app_script(
    TARGET PhotoBoothQt
    OUTPUT_SCRIPT deploy_script
    NO_UNSUPPORTED_PLATFORM_ERROR
)

install(TARGETS PhotoBoothQt
    BUNDLE DESTINATION .
    RUNTIME DESTINATION bin
)
install(SCRIPT ${deploy_script})

qt_add_executable(PhotoBoothQtTests
    tests/renderer_tests.cpp
    src/CollageDocument.cpp
    src/CollageDocument.h
    src/CollageRenderer.cpp
    src/CollageRenderer.h
)

target_link_libraries(PhotoBoothQtTests PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Test
)

add_test(NAME PhotoBoothQtTests COMMAND PhotoBoothQtTests)
