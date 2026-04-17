#include "PdfExporter.h"

#include "CollageDocument.h"
#include "CollageRenderer.h"

#include <QPageLayout>
#include <QPageSize>
#include <QPainter>
#include <QPdfWriter>

bool PdfExporter::exportA4Pdf(const CollageDocument &document, const QString &filePath, QString *errorMessage) const
{
    const CollageSnapshot snapshot = CollageRenderer::snapshotFromDocument(document);
    if (!snapshot.isValid()) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("Fill all 3 photo slots before exporting.");
        }
        return false;
    }

    if (filePath.isEmpty()) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("Choose a PDF destination.");
        }
        return false;
    }

    const QSize renderSize(1000, qRound(2000.0 * snapshot.stripLengthFactor));
    const QImage verticalStrip = CollageRenderer::renderStrip(snapshot, renderSize);
    const QImage rotated = CollageRenderer::rotateClockwise(verticalStrip);
    if (rotated.isNull()) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("Failed to render the collage.");
        }
        return false;
    }

    QPdfWriter writer(filePath);
    writer.setPageSize(QPageSize(QPageSize::A4));
    writer.setResolution(72);
    writer.setTitle(QStringLiteral("PhotoBooth A4 Export"));
    writer.setCreator(QStringLiteral("PhotoBoothQt"));

    QPainter painter(&writer);
    if (!painter.isActive()) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("Failed to open the PDF for writing.");
        }
        return false;
    }

    const QRectF pageRect = writer.pageLayout().paintRectPixels(writer.resolution());
    const double margin = 24.0;
    const double targetWidth = (pageRect.width() - (margin * 2.0)) * snapshot.collageWidthFraction;
    const double scale = targetWidth / rotated.width();
    const QSizeF drawSize(rotated.width() * scale, rotated.height() * scale);
    const QRectF drawRect(
        pageRect.center().x() - (drawSize.width() / 2.0),
        margin,
        drawSize.width(),
        drawSize.height()
    );

    painter.drawImage(drawRect, rotated);
    painter.end();
    return true;
}
