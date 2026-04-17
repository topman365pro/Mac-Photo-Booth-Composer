#include "CollageRenderer.h"

#include "CollageDocument.h"

#include <QPainter>
#include <QPainterPath>
#include <QPalette>
#include <QTransform>

bool CollageSnapshot::isValid() const
{
    for (const auto &photo : photos) {
        if (photo.isNull()) {
            return false;
        }
    }
    return true;
}

CollageSnapshot CollageRenderer::snapshotFromDocument(const CollageDocument &document)
{
    CollageSnapshot snapshot;
    for (int index = 0; index < 3; ++index) {
        snapshot.photos.at(index) = document.slotImage(index);
    }
    snapshot.background = document.backgroundImage();
    snapshot.spacing = document.spacing();
    snapshot.photoScale = document.photoScale();
    snapshot.insetTop = document.insetTop();
    snapshot.insetLeft = document.insetLeft();
    snapshot.insetRight = document.insetRight();
    snapshot.insetBottom = document.insetTop() + document.bottomMarginExtra();
    snapshot.cornerRadius = document.cornerRadius();
    snapshot.borderWidth = document.borderWidth();
    snapshot.drawBorder = document.drawBorder();
    snapshot.mirrorPhotos = document.mirrorPhotos();
    snapshot.stripLengthFactor = document.stripLengthFactor();
    snapshot.collageWidthFraction = document.collageWidthFraction();
    return snapshot;
}

QImage CollageRenderer::renderStrip(const CollageSnapshot &snapshot, const QSize &canvasSize)
{
    if (!snapshot.isValid() || !canvasSize.isValid()) {
        return {};
    }

    QImage canvas(canvasSize, QImage::Format_ARGB32_Premultiplied);
    canvas.fill(Qt::transparent);

    QPainter painter(&canvas);
    painter.setRenderHints(QPainter::Antialiasing | QPainter::SmoothPixmapTransform, true);

    const QRectF canvasRect(QPointF(0.0, 0.0), QSizeF(canvasSize));
    if (!snapshot.background.isNull()) {
        painter.drawImage(canvasRect, snapshot.background);
        painter.fillRect(canvasRect, QColor(0, 0, 0, 12));
    } else {
        painter.fillRect(canvasRect, QColor(245, 245, 245));
    }

    const double availableHeight = qMax(0.0, canvasRect.height() - snapshot.insetTop - snapshot.insetBottom);
    const double maxPhotoWidth = qMax(1.0, canvasRect.width() - snapshot.insetLeft - snapshot.insetRight);
    const double rawPhotoHeight = qMax(0.0, (availableHeight - (snapshot.spacing * 2.0)) / 3.0);
    const double targetAspect = 4.0 / 3.0;
    const double baseWidth = qMin(maxPhotoWidth, rawPhotoHeight * targetAspect);
    const double photoWidth = baseWidth * qMax(0.1, snapshot.photoScale);
    const double photoHeight = photoWidth / targetAspect;
    const double left = canvasRect.left() + snapshot.insetLeft + ((maxPhotoWidth - photoWidth) / 2.0);

    double top = canvasRect.bottom() - snapshot.insetTop - photoHeight;

    for (int index = 0; index < 3; ++index) {
        const QRectF frame(left, top, photoWidth, photoHeight);
        const QPainterPath clipPath = [&frame, &snapshot]() {
            QPainterPath path;
            path.addRoundedRect(frame, snapshot.cornerRadius, snapshot.cornerRadius);
            return path;
        }();

        painter.save();
        painter.setClipPath(clipPath);

        QImage image = snapshot.photos.at(index);
        if (snapshot.mirrorPhotos) {
            image = image.mirrored(true, false);
        }

        painter.drawImage(aspectFillRect(image.size(), frame), image);
        painter.restore();

        if (snapshot.drawBorder && snapshot.borderWidth > 0.0) {
            QPen pen(QColor(0, 0, 0, 140));
            pen.setWidthF(snapshot.borderWidth);
            painter.setPen(pen);
            painter.drawPath(clipPath);
        }

        top -= photoHeight + snapshot.spacing;
    }

    return canvas;
}

QImage CollageRenderer::rotateClockwise(const QImage &image)
{
    if (image.isNull()) {
        return {};
    }

    QTransform transform;
    transform.rotate(90.0);
    return image.transformed(transform, Qt::SmoothTransformation);
}

QRectF CollageRenderer::aspectFillRect(const QSizeF &sourceSize, const QRectF &targetRect)
{
    if (sourceSize.isEmpty() || targetRect.isEmpty()) {
        return targetRect;
    }

    const double scale = qMax(targetRect.width() / sourceSize.width(), targetRect.height() / sourceSize.height());
    const double width = sourceSize.width() * scale;
    const double height = sourceSize.height() * scale;
    return QRectF(
        targetRect.center().x() - (width / 2.0),
        targetRect.center().y() - (height / 2.0),
        width,
        height
    );
}
