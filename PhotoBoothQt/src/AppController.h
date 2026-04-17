#pragma once

#include "CollageDocument.h"
#include "PdfExporter.h"

#include <QObject>

class AppController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QObject* document READ document CONSTANT)
    Q_PROPERTY(QString exportMessage READ exportMessage NOTIFY exportMessageChanged)

public:
    explicit AppController(QObject *parent = nullptr);

    QObject *document();
    QString exportMessage() const;

    Q_INVOKABLE bool exportPdf(const QString &source);
    Q_INVOKABLE void clearExportMessage();

signals:
    void exportMessageChanged();

private:
    void ensureCameraPermission();
    void setExportMessage(const QString &message);
    static QString localPathForSource(const QString &source);

    CollageDocument m_document;
    PdfExporter m_pdfExporter;
    QString m_exportMessage;
};
