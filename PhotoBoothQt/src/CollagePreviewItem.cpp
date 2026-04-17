#include "CollagePreviewItem.h"

#include "CollageDocument.h"
#include "CollageRenderer.h"

#include <QPainter>

CollagePreviewItem::CollagePreviewItem(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
    setAntialiasing(true);
}

QObject *CollagePreviewItem::document() const
{
    return m_document;
}

void CollagePreviewItem::setDocument(QObject *document)
{
    auto *collageDocument = qobject_cast<CollageDocument *>(document);
    if (m_document == collageDocument) {
        return;
    }

    for (const auto &connection : m_connections) {
        disconnect(connection);
    }
    m_connections.clear();

    m_document = collageDocument;
    connectDocumentSignals();
    emit documentChanged();
    update();
}

void CollagePreviewItem::paint(QPainter *painter)
{
    painter->setRenderHints(QPainter::Antialiasing | QPainter::SmoothPixmapTransform, true);
    painter->fillRect(boundingRect(), Qt::transparent);

    if (!m_document) {
        return;
    }

    const CollageSnapshot snapshot = CollageRenderer::snapshotFromDocument(*m_document);
    if (!snapshot.isValid()) {
        painter->setPen(QColor(120, 120, 120));
        painter->drawText(boundingRect().adjusted(24.0, 24.0, -24.0, -24.0), Qt::AlignCenter,
                          QStringLiteral("Capture all 3 photos to preview the strip."));
        return;
    }

    const QSize renderSize(qMax(1, qRound(width())), qMax(1, qRound(height() * snapshot.stripLengthFactor)));
    const QImage rendered = CollageRenderer::renderStrip(snapshot, renderSize);
    if (rendered.isNull()) {
        return;
    }

    const QRectF bounds = boundingRect();
    const double targetWidth = bounds.width() * snapshot.collageWidthFraction;
    const double scale = targetWidth / rendered.width();
    const QSizeF drawSize(rendered.width() * scale, rendered.height() * scale);
    const QRectF drawRect((bounds.width() - drawSize.width()) / 2.0, 8.0, drawSize.width(), drawSize.height());
    painter->drawImage(drawRect, rendered);
}

void CollagePreviewItem::connectDocumentSignals()
{
    if (!m_document) {
        return;
    }

    auto subscribe = [this](auto signal) {
        m_connections.append(connect(m_document, signal, this, [this]() { update(); }));
    };

    subscribe(&CollageDocument::slotImagesChanged);
    subscribe(&CollageDocument::settingsChanged);
    subscribe(&CollageDocument::backgroundImageChanged);
}
