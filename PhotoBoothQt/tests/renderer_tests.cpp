#include "../src/CollageDocument.h"
#include "../src/CollageRenderer.h"

#include <QTest>
#include <QTemporaryDir>

class RendererTests : public QObject
{
    Q_OBJECT

private slots:
    void rendersStripWhenAllSlotsFilled();
    void reportsExportReadinessOnlyWhenAllSlotsFilled();
};

void RendererTests::rendersStripWhenAllSlotsFilled()
{
    CollageDocument document;
    QTemporaryDir tempDir;
    QVERIFY(tempDir.isValid());

    QImage red(640, 480, QImage::Format_RGB32);
    red.fill(Qt::red);
    QImage green(640, 480, QImage::Format_RGB32);
    green.fill(Qt::green);
    QImage blue(640, 480, QImage::Format_RGB32);
    blue.fill(Qt::blue);

    QVERIFY(!red.isNull());
    const QString redPath = tempDir.filePath(QStringLiteral("renderer-test-red.png"));
    const QString greenPath = tempDir.filePath(QStringLiteral("renderer-test-green.png"));
    const QString bluePath = tempDir.filePath(QStringLiteral("renderer-test-blue.png"));

    QVERIFY(red.save(redPath));
    QVERIFY(green.save(greenPath));
    QVERIFY(blue.save(bluePath));

    QVERIFY(document.setSlotImageFromSource(0, redPath));
    QVERIFY(document.setSlotImageFromSource(1, greenPath));
    QVERIFY(document.setSlotImageFromSource(2, bluePath));

    const CollageSnapshot snapshot = CollageRenderer::snapshotFromDocument(document);
    const QImage rendered = CollageRenderer::renderStrip(snapshot, QSize(600, 1200));
    QVERIFY(!rendered.isNull());
    QCOMPARE(rendered.size(), QSize(600, 1200));
}

void RendererTests::reportsExportReadinessOnlyWhenAllSlotsFilled()
{
    CollageDocument document;
    QVERIFY(!document.readyToExport());

    QTemporaryDir tempDir;
    QVERIFY(tempDir.isValid());

    QImage image(640, 480, QImage::Format_RGB32);
    image.fill(Qt::white);

    const QString filePath = tempDir.filePath(QStringLiteral("filled.png"));
    QVERIFY(image.save(filePath));

    QVERIFY(document.setSlotImageFromSource(0, filePath));
    QVERIFY(document.setSlotImageFromSource(1, filePath));
    QVERIFY(document.setSlotImageFromSource(2, filePath));
    QVERIFY(document.readyToExport());
}

QTEST_MAIN(RendererTests)

#include "renderer_tests.moc"
