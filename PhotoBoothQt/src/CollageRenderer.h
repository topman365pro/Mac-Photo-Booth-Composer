#pragma once

#include <QImage>
#include <QRectF>
#include <QSize>

#include <array>

class CollageDocument;

struct CollageSnapshot
{
    std::array<QImage, 3> photos;
    QImage background;
    double spacing = 70.0;
    double photoScale = 1.0;
    double insetTop = 140.0;
    double insetLeft = 90.0;
    double insetRight = 90.0;
    double insetBottom = 380.0;
    double cornerRadius = 8.0;
    double borderWidth = 1.0;
    bool drawBorder = true;
    bool mirrorPhotos = false;
    double stripLengthFactor = 1.6;
    double collageWidthFraction = 1.0;

    bool isValid() const;
};

class CollageRenderer
{
public:
    static CollageSnapshot snapshotFromDocument(const CollageDocument &document);
    static QImage renderStrip(const CollageSnapshot &snapshot, const QSize &canvasSize);
    static QImage rotateClockwise(const QImage &image);
    static QRectF aspectFillRect(const QSizeF &sourceSize, const QRectF &targetRect);
};
