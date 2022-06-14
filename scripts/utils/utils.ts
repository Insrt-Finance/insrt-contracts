import fs from 'fs';

export interface CoreAddresses {
  CoreDiamond: string;
  IndexDiamond: string;
  IndexManager: string;
  IndexBase: string;
  IndexIO: string;
  IndexView: string;
}

export interface Index {
  Index: string;
}

export interface MockToken {
  name: string;
  symbol: string;
  address: string;
}

export function readFile(filePath: string): any {
  if (fs.existsSync(filePath)) {
    try {
      return fs.readFileSync(filePath, 'utf8');
    } catch (error) {
      console.error(`An error occured: `, error);
    }
  } else {
    return [];
  }
}

export function createDir(_dirPath: string): void {
  if (!fs.existsSync(_dirPath)) {
    try {
      fs.mkdirSync(process.cwd() + _dirPath, { recursive: true });
    } catch (error) {
      console.error(`An error occurred: `, error);
    }
  }
}

export function createFile(
  filePath: string,
  fileContent: string | NodeJS.ArrayBufferView,
): void {
  try {
    fs.writeFileSync(filePath, fileContent);
  } catch (error) {
    console.error(`An error occurred: `, error);
  }
}
