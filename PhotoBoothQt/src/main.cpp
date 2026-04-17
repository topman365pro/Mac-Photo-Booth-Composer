#include "AppController.h"
#include "CollagePreviewItem.h"

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName(QStringLiteral("PhotoBooth"));
    QGuiApplication::setOrganizationName(QStringLiteral("PhotoBooth"));
    QGuiApplication::setApplicationDisplayName(QStringLiteral("PhotoBooth"));

    qmlRegisterType<CollagePreviewItem>("PhotoBooth", 1, 0, "CollagePreview");

    AppController controller;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("appController"), &controller);
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(EXIT_FAILURE); },
        Qt::QueuedConnection
    );
    engine.loadFromModule("PhotoBooth", "App");

    return app.exec();
}
