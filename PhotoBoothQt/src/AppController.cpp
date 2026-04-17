#include "AppController.h"

#include <QCoreApplication>
#include <QTimer>
#include <QUrl>

#if QT_CONFIG(permissions)
#include <QCameraPermission>
#endif

AppController::AppController(QObject *parent)
    : QObject(parent)
{
    QTimer::singleShot(0, this, &AppController::ensureCameraPermission);
}

QObject *AppController::document()
{
    return &m_document;
}

QString AppController::exportMessage() const
{
    return m_exportMessage;
}

bool AppController::exportPdf(const QString &source)
{
    QString errorMessage;
    const bool success = m_pdfExporter.exportA4Pdf(m_document, localPathForSource(source), &errorMessage);
    if (success) {
        setExportMessage(QStringLiteral("Saved PDF to %1").arg(localPathForSource(source)));
        return true;
    }

    setExportMessage(errorMessage);
    return false;
}

void AppController::clearExportMessage()
{
    setExportMessage({});
}

void AppController::ensureCameraPermission()
{
#if QT_CONFIG(permissions)
    auto *application = QCoreApplication::instance();
    if (!application) {
        return;
    }

    QCameraPermission permission;
    const auto status = application->checkPermission(permission);
    if (status == Qt::PermissionStatus::Granted) {
        m_document.setCameraStatus(QStringLiteral("Camera ready"));
        return;
    }

    if (status == Qt::PermissionStatus::Denied) {
        m_document.setCameraStatus(QStringLiteral("Camera access denied"));
        return;
    }

    application->requestPermission(permission, this, [this](const QPermission &grantedPermission) {
        if (grantedPermission.status() == Qt::PermissionStatus::Granted) {
            m_document.setCameraStatus(QStringLiteral("Camera ready"));
        } else {
            m_document.setCameraStatus(QStringLiteral("Camera access denied"));
        }
    });
#else
    m_document.setCameraStatus(QStringLiteral("Camera permission API unavailable"));
#endif
}

void AppController::setExportMessage(const QString &message)
{
    if (m_exportMessage == message) {
        return;
    }

    m_exportMessage = message;
    emit exportMessageChanged();
}

QString AppController::localPathForSource(const QString &source)
{
    const QUrl url = QUrl::fromUserInput(source);
    return url.isLocalFile() ? url.toLocalFile() : source;
}
