const ExcelJS = require('exceljs');

const TEMPLATE_COLUMNS = [
  'sku',
  'displayName',
  'category',
  'credits',
  'priceSilver',
  'priceGold',
  'pricePlatinum',
  'sortOrder',
  'isActive',
];

const YES_NO_COLUMNS = new Set([
  'isActive',
]);

function slugifyName(input) {
  return String(input || '')
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_|_$/g, '');
}

function boolToYesNo(value) {
  return value ? 'Yes' : 'No';
}

function parseYesNo(raw) {
  if (raw === undefined || raw === null || raw === '') return undefined;
  const value = String(raw).trim().toLowerCase();
  if (['yes', 'y', 'true', '1'].includes(value)) return true;
  if (['no', 'n', 'false', '0'].includes(value)) return false;
  throw new Error('Expected Yes or No');
}

function parseInteger(raw, fieldName) {
  if (raw === undefined || raw === null || raw === '') return undefined;
  const value = Number.parseInt(String(raw).trim(), 10);
  if (!Number.isFinite(value)) throw new Error(`Invalid integer for ${fieldName}`);
  return value;
}

function parseNumber(raw, fieldName) {
  if (raw === undefined || raw === null || raw === '') return undefined;
  const value = Number.parseFloat(String(raw).trim());
  if (!Number.isFinite(value)) throw new Error(`Invalid number for ${fieldName}`);
  return value;
}

function normalizeHeader(header) {
  return String(header || '')
    .trim()
    .replace(/\s+/g, '')
    .replace(/_/g, '')
    .toLowerCase();
}

function decodeCsvValue(raw) {
  if (raw === undefined || raw === null) return '';
  const text = String(raw).trim();
  if (text.startsWith('"') && text.endsWith('"')) {
    return text.slice(1, -1).replace(/""/g, '"');
  }
  return text;
}

function splitCsvLine(line) {
  const values = [];
  let cur = '';
  let inQuotes = false;

  for (let i = 0; i < line.length; i += 1) {
    const ch = line[i];
    const next = line[i + 1];

    if (ch === '"') {
      if (inQuotes && next === '"') {
        cur += '"';
        i += 1;
      } else {
        inQuotes = !inQuotes;
      }
      continue;
    }

    if (ch === ',' && !inQuotes) {
      values.push(cur);
      cur = '';
      continue;
    }

    cur += ch;
  }

  values.push(cur);
  return values.map(decodeCsvValue);
}

function toCsv(rows) {
  const escape = (value) => {
    const text = value === undefined || value === null ? '' : String(value);
    if (text.includes(',') || text.includes('"') || text.includes('\n')) {
      return `"${text.replace(/"/g, '""')}"`;
    }
    return text;
  };

  return rows
    .map((row) => row.map((cell) => escape(cell)).join(','))
    .join('\n');
}

function parseCsv(buffer) {
  const text = buffer.toString('utf8').replace(/^\uFEFF/, '');
  const lines = text
    .split(/\r?\n/)
    .map((line) => line.trimEnd())
    .filter((line) => line.length > 0);

  if (lines.length < 2) {
    return [];
  }

  const headers = splitCsvLine(lines[0]);
  const normalizedHeaders = headers.map(normalizeHeader);
  const headerMap = new Map();

  TEMPLATE_COLUMNS.forEach((column) => {
    const key = normalizeHeader(column);
    const index = normalizedHeaders.indexOf(key);
    if (index >= 0) headerMap.set(column, index);
  });

  const rows = [];
  for (let i = 1; i < lines.length; i += 1) {
    const values = splitCsvLine(lines[i]);
    const row = {};
    TEMPLATE_COLUMNS.forEach((column) => {
      const idx = headerMap.get(column);
      row[column] = idx !== undefined ? values[idx] : '';
    });
    rows.push({ rowNumber: i + 1, row });
  }

  return rows;
}

async function parseXlsx(buffer) {
  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.load(buffer);
  const worksheet = workbook.getWorksheet('Packs') || workbook.worksheets[0];
  if (!worksheet) return [];

  const headerRow = worksheet.getRow(1);
  const headers = headerRow.values
    .slice(1)
    .map((v) => String(v || ''));

  const normalizedHeaders = headers.map(normalizeHeader);
  const headerMap = new Map();

  TEMPLATE_COLUMNS.forEach((column) => {
    const idx = normalizedHeaders.indexOf(normalizeHeader(column));
    if (idx >= 0) headerMap.set(column, idx + 1);
  });

  const rows = [];
  for (let rowIndex = 2; rowIndex <= worksheet.rowCount; rowIndex += 1) {
    const excelRow = worksheet.getRow(rowIndex);
    if (!excelRow || !excelRow.hasValues) continue;

    const row = {};
    TEMPLATE_COLUMNS.forEach((column) => {
      const colIdx = headerMap.get(column);
      const cellValue = colIdx ? excelRow.getCell(colIdx).value : '';
      if (cellValue && typeof cellValue === 'object' && cellValue.text !== undefined) {
        row[column] = String(cellValue.text);
      } else {
        row[column] = cellValue === undefined || cellValue === null ? '' : String(cellValue);
      }
    });

    const hasAnyValue = Object.values(row).some((v) => String(v).trim().length > 0);
    if (!hasAnyValue) continue;
    rows.push({ rowNumber: rowIndex, row });
  }

  return rows;
}

function normalizeImportRows(rawRows, options) {
  const { isValidCategory } = options;
  const errors = [];
  const rows = [];

  rawRows.forEach(({ rowNumber, row }) => {
    try {
      const sku = String(row.sku || '').trim();
      const displayName = String(row.displayName || '').trim();
      const category = String(row.category || '').trim().toLowerCase();

      if (!sku) throw new Error('sku is required');
      if (!displayName) throw new Error('displayName is required');
      if (!category) throw new Error('category is required');
      if (!isValidCategory(category)) throw new Error('invalid category');

      const credits = parseInteger(row.credits, 'credits');
      if (credits === undefined || credits < 0) {
        throw new Error('credits must be a non-negative integer');
      }

      const priceSilver = parseNumber(row.priceSilver, 'priceSilver');
      if (priceSilver === undefined || priceSilver < 0) {
        throw new Error('priceSilver must be a non-negative number');
      }

      const priceGold = parseNumber(row.priceGold, 'priceGold');
      if (priceGold === undefined || priceGold < 0) {
        throw new Error('priceGold must be a non-negative number');
      }

      const pricePlatinum = parseNumber(row.pricePlatinum, 'pricePlatinum');
      if (pricePlatinum === undefined || pricePlatinum < 0) {
        throw new Error('pricePlatinum must be a non-negative number');
      }

      const normalized = {
        sku,
        displayName,
        category,
        credits,
        priceSilver,
        priceGold,
        pricePlatinum,
        sortOrder: parseInteger(row.sortOrder, 'sortOrder') ?? 0,
        isActive: parseYesNo(row.isActive) ?? true,
      };

      rows.push({ rowNumber, payload: normalized });
    } catch (error) {
      errors.push({ rowNumber, message: error.message });
    }
  });

  return { rows, errors };
}

function packsToExportRows(packs) {
  return packs.map((pack) => ({
    sku: pack.sku,
    displayName: pack.displayName,
    category: pack.category || '',
    credits: pack.credits,
    priceSilver: Number(pack.priceSilver),
    priceGold: Number(pack.priceGold),
    pricePlatinum: Number(pack.pricePlatinum),
    sortOrder: pack.sortOrder,
    isActive: boolToYesNo(pack.isActive),
  }));
}

async function buildTemplateXlsx(options) {
  const { categories } = options;
  const workbook = new ExcelJS.Workbook();
  const sheet = workbook.addWorksheet('Packs');

  sheet.addRow(TEMPLATE_COLUMNS);
  sheet.addRow([
    'starter_100_retail',
    'Starter Pack - 100 Credits',
    'retail',
    '100',
    '99',
    '89',
    '79',
    '10',
    'Yes',
  ]);

  sheet.columns = TEMPLATE_COLUMNS.map((column) => ({
    key: column,
    width: Math.max(14, column.length + 3),
  }));

  const headerRow = sheet.getRow(1);
  headerRow.font = { bold: true };

  // Apply dropdown validations for spreadsheet users.
  for (let row = 2; row <= 1000; row += 1) {
    sheet.getCell(`C${row}`).dataValidation = {
      type: 'list',
      allowBlank: false,
      formulae: [`"${categories.join(',')}"`],
    };

    YES_NO_COLUMNS.forEach((column) => {
      const colIndex = TEMPLATE_COLUMNS.indexOf(column) + 1;
      const letter = sheet.getColumn(colIndex).letter;
      sheet.getCell(`${letter}${row}`).dataValidation = {
        type: 'list',
        allowBlank: true,
        formulae: ['"Yes,No"'],
      };
    });
  }

  const notesSheet = workbook.addWorksheet('Notes');
  notesSheet.addRow(['Field', 'Notes']);
  notesSheet.addRow(['sku', 'Unique identifier for the pack']);
  notesSheet.addRow(['displayName', 'User-friendly name for the pack']);
  notesSheet.addRow(['category', `Allowed values: ${categories.join(', ')}`]);
  notesSheet.addRow(['credits', 'Number of AI credits in this pack']);
  notesSheet.addRow(['priceSilver', 'Price for silver tier customers']);
  notesSheet.addRow(['priceGold', 'Price for gold tier customers']);
  notesSheet.addRow(['pricePlatinum', 'Price for platinum tier customers']);
  notesSheet.addRow(['sortOrder', 'Display order (lower values appear first)']);
  notesSheet.addRow(['isActive', 'Use Yes or No to enable/disable the pack']);
  notesSheet.columns = [{ width: 24 }, { width: 110 }];

  return workbook.xlsx.writeBuffer();
}

function buildTemplateCsv() {
  const rows = [
    TEMPLATE_COLUMNS,
    [
      'starter_100_retail',
      'Starter Pack - 100 Credits',
      'retail',
      '100',
      '99',
      '89',
      '79',
      '10',
      'Yes',
    ],
  ];
  return Buffer.from(toCsv(rows), 'utf8');
}

async function buildExportXlsx(rows) {
  const workbook = new ExcelJS.Workbook();
  const sheet = workbook.addWorksheet('PacksExport');
  sheet.addRow(TEMPLATE_COLUMNS);
  rows.forEach((row) => {
    sheet.addRow(TEMPLATE_COLUMNS.map((column) => row[column] ?? ''));
  });
  sheet.columns = TEMPLATE_COLUMNS.map((column) => ({
    key: column,
    width: Math.max(14, column.length + 4),
  }));
  sheet.getRow(1).font = { bold: true };
  return workbook.xlsx.writeBuffer();
}

function buildExportCsv(rows) {
  const matrix = [
    TEMPLATE_COLUMNS,
    ...rows.map((row) => TEMPLATE_COLUMNS.map((column) => row[column] ?? '')),
  ];
  return Buffer.from(toCsv(matrix), 'utf8');
}

async function parsePackFile({ fileBuffer, fileName, format }) {
  const detectedFormat = (format || '').toLowerCase();
  const lowerName = String(fileName || '').toLowerCase();

  if (detectedFormat === 'xlsx' || lowerName.endsWith('.xlsx')) {
    return parseXlsx(fileBuffer);
  }

  return parseCsv(fileBuffer);
}

module.exports = {
  TEMPLATE_COLUMNS,
  packsToExportRows,
  normalizeImportRows,
  buildTemplateXlsx,
  buildTemplateCsv,
  buildExportXlsx,
  buildExportCsv,
  parsePackFile,
};
