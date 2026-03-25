const MEAL_WINDOWS = {
  breakfast: { startMinutes: 7 * 60, endMinutes: 8 * 60 },
  lunch: { startMinutes: 12 * 60, endMinutes: 13 * 60 },
  dinner: { startMinutes: 18 * 60 + 30, endMinutes: 21 * 60 + 30 },
};

function getMealByServerTime(now = new Date()) {
  const totalMinutes = now.getHours() * 60 + now.getMinutes();

  for (const [meal, window] of Object.entries(MEAL_WINDOWS)) {
    if (
      totalMinutes >= window.startMinutes &&
      totalMinutes < window.endMinutes
    ) {
      return meal;
    }
  }

  return null;
}

function getDateId(now = new Date()) {
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

module.exports = {
  MEAL_WINDOWS,
  getMealByServerTime,
  getDateId,
};
