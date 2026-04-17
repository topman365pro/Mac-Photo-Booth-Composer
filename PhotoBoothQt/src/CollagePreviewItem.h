#pragma once

#include <QPointer>
#include <QQuickPaintedItem>

class CollageDocument;

class CollagePreviewItem : public QQuickPaintedItem
{
    Q_OBJECT
    Q_PROPERTY(QObject* document READ document WRITE setDocument NOTIFY documentChanged)

public:
    explicit CollagePreviewItem(QQuickItem *parent = nullptr);

    QObject *document() const;
    void setDocument(QObject *document);

    void paint(QPainter *painter) override;

signals:
    void documentChanged();

private:
    void connectDocumentSignals();

    QPointer<CollageDocument> m_document;
    QList<QMetaObject::Connection> m_connections;
};
