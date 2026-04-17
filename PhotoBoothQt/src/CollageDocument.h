#pragma once

#include <QObject>
#include <QImage>
#include <QUrl>

#include <array>

class CollageDocument : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int activeSlot READ activeSlot WRITE setActiveSlot NOTIFY activeSlotChanged)
    Q_PROPERTY(QString selectedCameraId READ selectedCameraId WRITE setSelectedCameraId NOTIFY selectedCameraIdChanged)
    Q_PROPERTY(bool torchEnabled READ torchEnabled WRITE setTorchEnabled NOTIFY torchEnabledChanged)
    Q_PROPERTY(bool torchSupported READ torchSupported WRITE setTorchSupported NOTIFY torchSupportedChanged)
    Q_PROPERTY(double spacing READ spacing WRITE setSpacing NOTIFY settingsChanged)
    Q_PROPERTY(double photoScale READ photoScale WRITE setPhotoScale NOTIFY settingsChanged)
    Q_PROPERTY(double insetTop READ insetTop WRITE setInsetTop NOTIFY settingsChanged)
    Q_PROPERTY(double insetLeft READ insetLeft WRITE setInsetLeft NOTIFY settingsChanged)
    Q_PROPERTY(double insetRight READ insetRight WRITE setInsetRight NOTIFY settingsChanged)
    Q_PROPERTY(double cornerRadius READ cornerRadius WRITE setCornerRadius NOTIFY settingsChanged)
    Q_PROPERTY(bool drawBorder READ drawBorder WRITE setDrawBorder NOTIFY settingsChanged)
    Q_PROPERTY(double borderWidth READ borderWidth WRITE setBorderWidth NOTIFY settingsChanged)
    Q_PROPERTY(bool mirrorPhotos READ mirrorPhotos WRITE setMirrorPhotos NOTIFY settingsChanged)
    Q_PROPERTY(double stripLengthFactor READ stripLengthFactor WRITE setStripLengthFactor NOTIFY settingsChanged)
    Q_PROPERTY(double bottomMarginExtra READ bottomMarginExtra WRITE setBottomMarginExtra NOTIFY settingsChanged)
    Q_PROPERTY(double collageWidthFraction READ collageWidthFraction WRITE setCollageWidthFraction NOTIFY settingsChanged)
    Q_PROPERTY(QString cameraStatus READ cameraStatus WRITE setCameraStatus NOTIFY cameraStatusChanged)
    Q_PROPERTY(QUrl backgroundImageUrl READ backgroundImageUrl NOTIFY backgroundImageChanged)
    Q_PROPERTY(bool readyToExport READ readyToExport NOTIFY slotImagesChanged)

public:
    explicit CollageDocument(QObject *parent = nullptr);

    int activeSlot() const;
    void setActiveSlot(int slot);

    QString selectedCameraId() const;
    void setSelectedCameraId(const QString &cameraId);

    bool torchEnabled() const;
    void setTorchEnabled(bool enabled);

    bool torchSupported() const;
    void setTorchSupported(bool supported);

    double spacing() const;
    void setSpacing(double value);

    double photoScale() const;
    void setPhotoScale(double value);

    double insetTop() const;
    void setInsetTop(double value);

    double insetLeft() const;
    void setInsetLeft(double value);

    double insetRight() const;
    void setInsetRight(double value);

    double cornerRadius() const;
    void setCornerRadius(double value);

    bool drawBorder() const;
    void setDrawBorder(bool value);

    double borderWidth() const;
    void setBorderWidth(double value);

    bool mirrorPhotos() const;
    void setMirrorPhotos(bool value);

    double stripLengthFactor() const;
    void setStripLengthFactor(double value);

    double bottomMarginExtra() const;
    void setBottomMarginExtra(double value);

    double collageWidthFraction() const;
    void setCollageWidthFraction(double value);

    QString cameraStatus() const;
    void setCameraStatus(const QString &status);

    QUrl backgroundImageUrl() const;
    bool readyToExport() const;

    Q_INVOKABLE QUrl slotSource(int index) const;
    Q_INVOKABLE bool hasSlotImage(int index) const;
    Q_INVOKABLE bool setSlotImageFromSource(int index, const QString &source);
    Q_INVOKABLE void clearSlot(int index);
    Q_INVOKABLE int nextRecommendedSlot() const;
    Q_INVOKABLE bool setBackgroundImageFromSource(const QString &source);
    Q_INVOKABLE void clearBackgroundImage();

    QImage slotImage(int index) const;
    QImage backgroundImage() const;

signals:
    void activeSlotChanged();
    void selectedCameraIdChanged();
    void torchEnabledChanged();
    void torchSupportedChanged();
    void settingsChanged();
    void slotImagesChanged();
    void backgroundImageChanged();
    void cameraStatusChanged();

private:
    static QString localPathForSource(const QString &source);
    static QImage imageFromSource(const QString &source);
    static bool isDifferent(double lhs, double rhs);
    void emitSettingsChanged();

    int m_activeSlot = 0;
    QString m_selectedCameraId;
    bool m_torchEnabled = false;
    bool m_torchSupported = false;
    double m_spacing = 70.0;
    double m_photoScale = 1.0;
    double m_insetTop = 140.0;
    double m_insetLeft = 90.0;
    double m_insetRight = 90.0;
    double m_cornerRadius = 8.0;
    bool m_drawBorder = true;
    double m_borderWidth = 1.0;
    bool m_mirrorPhotos = false;
    double m_stripLengthFactor = 1.6;
    double m_bottomMarginExtra = 240.0;
    double m_collageWidthFraction = 1.0;
    QString m_cameraStatus;
    std::array<QImage, 3> m_slotImages;
    std::array<QUrl, 3> m_slotUrls;
    QImage m_backgroundImage;
    QUrl m_backgroundImageUrl;
};
