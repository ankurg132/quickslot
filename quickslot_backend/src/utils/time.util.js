/**
 * Helper: Format database time "HH:MM:SS" to "HH:MM"
 * @param {string} timeStr - Time string from the database
 * @returns {string} Formatted time string
 */
function formatDbTime(timeStr) {
  if (!timeStr) return '';
  const parts = timeStr.split(':');
  if (parts.length >= 2) {
    return `${parts[0]}:${parts[1]}`;
  }
  return timeStr;
}

module.exports = {
  formatDbTime,
};
