#pragma once

#include <QString>

class CollageDocument;

class PdfExporter
{
public:
    bool exportA4Pdf(const CollageDocument &document, const QString &filePath, QString *errorMessage) const;
};
