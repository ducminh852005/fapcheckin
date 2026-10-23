// Phân tích văn bản OCR của ảnh thời khóa biểu GV và đối chiếu với collection `classes`.
// Port từ TimetableImportService.gs (Apps Script cũ). Hàm thuần, không phụ thuộc Firebase.

const text = (value) => (value == null ? '' : String(value).trim());
const normalizedCode = (value) => text(value).toUpperCase().replace(/[^A-Z0-9]/g, '');

/** Rút các cặp mã lớp–môn (SE1917-PRN232), phòng và ngày tuần từ văn bản OCR nhiễu. */
export function parseText(ocrText) {
  const source = text(ocrText)
    .toUpperCase()
    .replace(/[–—−_]/g, '-')
    .replace(/\r/g, '\n')
    // OCR đôi khi chèn dấu cách vào giữa mã.
    .replace(/\b([A-Z]{2,4})\s+(\d{3,5})\b/g, '$1$2')
    .replace(/\b([A-Z]{2,5})\s+(\d{3})\b/g, '$1$2');

  const entries = [];
  const seen = new Set();
  // Khớp phần ổn định (cặp mã) trước; yêu cầu "at NVH" từng làm ảnh rõ bị từ chối
  // khi OCR đảo cột hoặc mất nhãn.
  const pattern = /\b([A-Z]{2,4}\d{3,5})(?:\s*-\s*|\s+)([A-Z]{2,5}\d{3})\b/g;
  let match;
  while ((match = pattern.exec(source)) !== null) {
    const [, classCode, subjectCode] = match;
    const key = `${classCode}|${subjectCode}`;
    if (seen.has(key)) continue;
    seen.add(key);
    // Phòng nằm gần mã; giới hạn cửa sổ tìm để không lấy nhầm phòng của ô kế bên.
    const afterCode = source.slice(pattern.lastIndex, pattern.lastIndex + 60);
    const roomMatch = /^\s+AT\s+[A-Z]{2,8}(?:\s*-)?\s*(\d{3,4}|[A-Z]\d{2,4})\b/.exec(afterCode);
    entries.push({ key, classCode, subjectCode, room: roomMatch ? roomMatch[1] : '' });
  }

  const detectedDates = [];
  const dateSeen = new Set();
  const datePattern = /\b(\d{1,2})[/-](\d{1,2})(?:[/-](\d{2,4}))?\b/g;
  while ((match = datePattern.exec(source)) !== null) {
    const day = match[1].padStart(2, '0');
    const month = match[2].padStart(2, '0');
    const value = `${day}/${month}${match[3] ? `/${match[3]}` : ''}`;
    if (!dateSeen.has(value)) {
      dateSeen.add(value);
      detectedDates.push(value);
    }
  }
  return { entries, detectedDates };
}

export function subjectCodeOf(classRow) {
  const direct = normalizedCode(classRow.subjectCode);
  if (direct) return direct;
  for (const part of text(classRow.classCode).toUpperCase().split(/[^A-Z0-9]+/)) {
    if (/^[A-Z]{2,5}\d{3}$/.test(part)) return part;
  }
  const fromName = /^([A-Z]{2,5}\d{3})\b/.exec(text(classRow.subjectName).toUpperCase());
  return fromName ? normalizedCode(fromName[1]) : '';
}

/**
 * Đối chiếu từng cặp mã với `classes`.
 * status: available | alreadyAssigned | conflict | ambiguous | notFound
 */
export function matchEntries(parsed, classes, teacherMemberCode) {
  return parsed.entries.map((entry) => {
    const wantedClass = normalizedCode(entry.classCode);
    const wantedSubject = normalizedCode(entry.subjectCode);
    const matches = classes.filter((row) => {
      const rowClass = normalizedCode(row.classCode);
      const classMatches =
        rowClass === wantedClass ||
        rowClass === wantedClass + wantedSubject ||
        rowClass === wantedSubject + wantedClass;
      return classMatches && subjectCodeOf(row) === wantedSubject;
    });
    const result = {
      key: entry.key,
      classCode: entry.classCode,
      subjectCode: entry.subjectCode,
      room: entry.room,
      matchedClassCode: null,
      status: 'notFound',
      message: 'Không tìm thấy lớp tương ứng trong danh sách lớp.',
    };
    if (matches.length > 1) {
      return { ...result, status: 'ambiguous', message: 'Có nhiều lớp trùng mã; cần kiểm tra dữ liệu nhà trường.' };
    }
    if (matches.length === 0) return result;
    const matched = matches[0];
    result.matchedClassCode = text(matched.classCode);
    const owner = text(matched.teacherMemberCode);
    if (!owner) {
      result.status = 'available';
      result.message = 'Sẵn sàng thêm vào lớp.';
    } else if (owner === text(teacherMemberCode)) {
      result.status = 'alreadyAssigned';
      result.message = 'Giáo viên đã có trong lớp này.';
    } else {
      result.status = 'conflict';
      result.message = 'Lớp đã được phân công cho giáo viên khác.';
    }
    return result;
  });
}
