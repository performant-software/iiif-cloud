const FILE_SIZE_UNITS = ['B', 'kB', 'MB', 'GB', 'TB'];

/**
 * Returns the human-readable file size for the passed bytes.
 *
 * @param size
 *
 * @returns {`${number} ${string}`}
 */
const getFileSize = (size: number) => {
  const i = size === 0 ? 0 : Math.floor(Math.log(size) / Math.log(1024));
  const fileSize = ((size / 1024 ** i).toFixed(2)) * 1;

  return `${fileSize} ${FILE_SIZE_UNITS[i]}`;
};

export default {
  getFileSize
};
