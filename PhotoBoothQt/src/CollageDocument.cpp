#include "CollageDocument.h"

#include <QImageReader>
#include <QtMath>

namespace {
constexpr int kSlotCount = 3;
}

CollageDocument::CollageDocument(QObject *parent)
    : QObject(parent)
{
}

int CollageDocument::activeSlot() const
{
    return m_activeSlot;
}

void CollageDocument::setActiveSlot(int slot)
{
    const int clamped = qBound(0, slot, kSlotCount - 1);
    if (m_activeSlot == clamped) {
        return;
    }

    m_activeSlot = clamped;
    emit activeSlotChanged();
}

QString CollageDocument::selectedCameraId() const
{
    return m_selectedCameraId;
}

void CollageDocument::setSelectedCameraId(const QString &cameraId)
{
    if (m_selectedCameraId == cameraId) {
        return;
    }

    m_selectedCameraId = cameraId;
    emit selectedCameraIdChanged();
}

bool CollageDocument::torchEnabled() const
{
    return m_torchEnabled;
}

void CollageDocument::setTorchEnabled(bool enabled)
{
    if (m_torchEnabled == enabled) {
        return;
    }

    m_torchEnabled = enabled;
    emit torchEnabledChanged();
}

bool CollageDocument::torchSupported() const
{
    return m_torchSupported;
}

void CollageDocument::setTorchSupported(bool supported)
{
    if (m_torchSupported == supported) {
        return;
    }

    m_torchSupported = supported;
    if (!supported && m_torchEnabled) {
        m_torchEnabled = false;
        emit torchEnabledChanged();
    }
    emit torchSupportedChanged();
}

double CollageDocument::spacing() const
{
    return m_spacing;
}

void CollageDocument::setSpacing(double value)
{
    const double clamped = qBound(0.0, value, 600.0);
    if (!isDifferent(m_spacing, clamped)) {
        return;
    }

    m_spacing = clamped;
    emitSettingsChanged();
}

double CollageDocument::photoScale() const
{
    return m_photoScale;
}

void CollageDocument::setPhotoScale(double value)
{
    const double clamped = qBound(0.5, value, 1.0);
    if (!isDifferent(m_photoScale, clamped)) {
        return;
    }

    m_photoScale = clamped;
    emitSettingsChanged();
}

double CollageDocument::insetTop() const
{
    return m_insetTop;
}

void CollageDocument::setInsetTop(double value)
{
    const double clamped = qBound(0.0, value, 600.0);
    if (!isDifferent(m_insetTop, clamped)) {
        return;
    }

    m_insetTop = clamped;
    emitSettingsChanged();
}

double CollageDocument::insetLeft() const
{
    return m_insetLeft;
}

void CollageDocument::setInsetLeft(double value)
{
    const double clamped = qBound(0.0, value, 600.0);
    if (!isDifferent(m_insetLeft, clamped)) {
        return;
    }

    m_insetLeft = clamped;
    emitSettingsChanged();
}

double CollageDocument::insetRight() const
{
    return m_insetRight;
}

void CollageDocument::setInsetRight(double value)
{
    const double clamped = qBound(0.0, value, 600.0);
    if (!isDifferent(m_insetRight, clamped)) {
        return;
    }

    m_insetRight = clamped;
    emitSettingsChanged();
}

double CollageDocument::cornerRadius() const
{
    return m_cornerRadius;
}

void CollageDocument::setCornerRadius(double value)
{
    const double clamped = qBound(0.0, value, 80.0);
    if (!isDifferent(m_cornerRadius, clamped)) {
        return;
    }

    m_cornerRadius = clamped;
    emitSettingsChanged();
}

bool CollageDocument::drawBorder() const
{
    return m_drawBorder;
}

void CollageDocument::setDrawBorder(bool value)
{
    if (m_drawBorder == value) {
        return;
    }

    m_drawBorder = value;
    emitSettingsChanged();
}

double CollageDocument::borderWidth() const
{
    return m_borderWidth;
}

void CollageDocument::setBorderWidth(double value)
{
    const double clamped = qBound(0.5, value, 20.0);
    if (!isDifferent(m_borderWidth, clamped)) {
        return;
    }

    m_borderWidth = clamped;
    emitSettingsChanged();
}

bool CollageDocument::mirrorPhotos() const
{
    return m_mirrorPhotos;
}

void CollageDocument::setMirrorPhotos(bool value)
{
    if (m_mirrorPhotos == value) {
        return;
    }

    m_mirrorPhotos = value;
    emitSettingsChanged();
}

double CollageDocument::stripLengthFactor() const
{
    return m_stripLengthFactor;
}

void CollageDocument::setStripLengthFactor(double value)
{
    const double clamped = qBound(0.6, value, 2.5);
    if (!isDifferent(m_stripLengthFactor, clamped)) {
        return;
    }

    m_stripLengthFactor = clamped;
    emitSettingsChanged();
}

double CollageDocument::bottomMarginExtra() const
{
    return m_bottomMarginExtra;
}

void CollageDocument::setBottomMarginExtra(double value)
{
    const double clamped = qBound(0.0, value, 600.0);
    if (!isDifferent(m_bottomMarginExtra, clamped)) {
        return;
    }

    m_bottomMarginExtra = clamped;
    emitSettingsChanged();
}

double CollageDocument::collageWidthFraction() const
{
    return m_collageWidthFraction;
}

void CollageDocument::setCollageWidthFraction(double value)
{
    const double clamped = qBound(0.1, value, 1.0);
    if (!isDifferent(m_collageWidthFraction, clamped)) {
        return;
    }

    m_collageWidthFraction = clamped;
    emitSettingsChanged();
}

QString CollageDocument::cameraStatus() const
{
    return m_cameraStatus;
}

void CollageDocument::setCameraStatus(const QString &status)
{
    if (m_cameraStatus == status) {
        return;
    }

    m_cameraStatus = status;
    emit cameraStatusChanged();
}

QUrl CollageDocument::backgroundImageUrl() const
{
    return m_backgroundImageUrl;
}

bool CollageDocument::readyToExport() const
{
    for (const auto &slotImage : m_slotImages) {
        if (slotImage.isNull()) {
            return false;
        }
    }
    return true;
}

QUrl CollageDocument::slotSource(int index) const
{
    if (index < 0 || index >= kSlotCount) {
        return {};
    }
    return m_slotUrls.at(index);
}

bool CollageDocument::hasSlotImage(int index) const
{
    if (index < 0 || index >= kSlotCount) {
        return false;
    }
    return !m_slotImages.at(index).isNull();
}

bool CollageDocument::setSlotImageFromSource(int index, const QString &source)
{
    if (index < 0 || index >= kSlotCount) {
        return false;
    }

    const QImage image = imageFromSource(source);
    if (image.isNull()) {
        return false;
    }

    m_slotImages.at(index) = image;
    m_slotUrls.at(index) = QUrl::fromLocalFile(localPathForSource(source));
    emit slotImagesChanged();
    return true;
}

void CollageDocument::clearSlot(int index)
{
    if (index < 0 || index >= kSlotCount) {
        return;
    }

    if (m_slotImages.at(index).isNull()) {
        return;
    }

    m_slotImages.at(index) = QImage();
    m_slotUrls.at(index) = {};
    emit slotImagesChanged();
}

int CollageDocument::nextRecommendedSlot() const
{
    for (int offset = 1; offset <= kSlotCount; ++offset) {
        const int index = (m_activeSlot + offset) % kSlotCount;
        if (m_slotImages.at(index).isNull()) {
            return index;
        }
    }

    return (m_activeSlot + 1) % kSlotCount;
}

bool CollageDocument::setBackgroundImageFromSource(const QString &source)
{
    const QImage image = imageFromSource(source);
    if (image.isNull()) {
        return false;
    }

    m_backgroundImage = image;
    m_backgroundImageUrl = QUrl::fromLocalFile(localPathForSource(source));
    emit backgroundImageChanged();
    return true;
}

void CollageDocument::clearBackgroundImage()
{
    if (m_backgroundImage.isNull() && !m_backgroundImageUrl.isValid()) {
        return;
    }

    m_backgroundImage = QImage();
    m_backgroundImageUrl = {};
    emit backgroundImageChanged();
}

QImage CollageDocument::slotImage(int index) const
{
    if (index < 0 || index >= kSlotCount) {
        return {};
    }
    return m_slotImages.at(index);
}

QImage CollageDocument::backgroundImage() const
{
    return m_backgroundImage;
}

QString CollageDocument::localPathForSource(const QString &source)
{
    const QUrl url = QUrl::fromUserInput(source);
    return url.isLocalFile() ? url.toLocalFile() : source;
}

QImage CollageDocument::imageFromSource(const QString &source)
{
    const QString localPath = localPathForSource(source);
    if (localPath.isEmpty()) {
        return {};
    }

    QImageReader reader(localPath);
    reader.setAutoTransform(true);
    return reader.read();
}

bool CollageDocument::isDifferent(double lhs, double rhs)
{
    return !qFuzzyCompare(lhs + 1.0, rhs + 1.0);
}

void CollageDocument::emitSettingsChanged()
{
    emit settingsChanged();
}
