<template>
  <main class="moodmapper" :class="{ 'dark-mode': isDarkMode }">
    <div class="funky-background"></div>
    <div v-if="isLoading" class="loader-container">
      <div class="loader"></div>
    </div>
    <div v-else class="dashboard-layout">
      <!-- Left Column - Original Interface -->
      <div class="content left-column">
        <div class="header">
          <h1 class="title">Moodmapper</h1>
          <label class="switch">
            <input type="checkbox" v-model="isDarkMode" />
            <span class="slider round"></span>
          </label>
        </div>

        <div class="mood-input">
          <h3>How are you feeling today?</h3>
          <div class="slider-container">
            <input type="range" id="mood" name="mood" step="1" min="1" max="10" v-model="mood" aria-label="Select mood level from 1 to 10" />
            <div class="mood-emoji-track">
              <div class="mood-emoji" :style="{ left: `${emojiPosition}%` }">
                {{ moodEmoji }}
              </div>
            </div>
          </div>
          <div class="notes-input">
            <label for="notes">Add notes (optional):</label>
            <textarea id="notes" v-model="currentNote" placeholder="How was your day? What made you feel this way?" rows="3" aria-label="Add notes about your mood"></textarea>
          </div>
          <button class="submit-btn" @click="saveMood" :disabled="isSubmitting" aria-label="Save mood entry">
            {{ isSubmitting ? "Saving..." : "Capture Mood" }}
          </button>
        </div>

        <div class="mood-list">
          <h2>Recent Entries</h2>
          <transition-group name="list" tag="ul" appear>
            <li v-for="(entry, index) in recentMoodEntries" :key="entry.timestamp" class="mood-entry">
              <div class="mood-info">
                <span class="mood-emoji" role="img" :aria-label="getMoodLabel(entry.mood)">
                  {{ getMoodEmoji(entry.mood) }}
                </span>
                <span class="mood-details">
                  <strong>Mood: {{ entry.mood }}</strong>
                  <br />
                  <small>{{ getRelativeTime(entry.timestamp) }}</small>
                  <p v-if="entry.notes" class="entry-notes">{{ entry.notes }}</p>
                </span>
              </div>
              <button class="delete-btn" @click="deleteMoodEntry(index)" aria-label="Delete mood entry">&times;</button>
            </li>
          </transition-group>
        </div>
      </div>

      <!-- Right Column - Analytics -->
      <div class="content right-column">
        <div class="analytics-header">
          <h2>Mood Analytics</h2>
          <div class="time-range-selector" role="group" aria-label="Select time range">
            <button v-for="range in timeRanges" :key="range" @click="selectedTimeRange = range" :class="{ active: selectedTimeRange === range }" class="time-range-btn" :aria-pressed="selectedTimeRange === range">
              {{ range }}
            </button>
          </div>
        </div>

        <!-- Mood Trend Chart -->
        <div class="chart-container">
          <h3 class="chart-title">Mood Trends</h3>
          <ClientOnly>
            <apexchart type="line" :options="trendChartOptions" :series="trendChartSeries" height="300" />
          </ClientOnly>
        </div>

        <!-- Mood Distribution Chart -->
        <div class="chart-container">
          <h3 class="chart-title">Mood Distribution</h3>
          <ClientOnly>
            <apexchart type="bar" :options="distributionChartOptions" :series="distributionChartSeries" height="250" />
          </ClientOnly>
        </div>
      </div>
    </div>
  </main>
</template>

<script setup lang="ts">
import { computed, onMounted, ref, watch } from "vue";

interface MoodEntry {
  mood: number;
  timestamp: string;
  notes?: string;
}

const mood = defineModel<number>();
mood.value = 5; // Start at neutral mood

const moodEntries = ref<MoodEntry[]>([]);
const currentNote = ref("");
const isSubmitting = ref(false);
const isDarkMode = ref(false);
const isLoading = ref(true);
const timeRanges = ["Week", "Month", "Year"] as const;
const selectedTimeRange = ref<(typeof timeRanges)[number]>("Week");

// Computed properties for core functionality
const emojiPosition = computed(() => {
  return ((mood.value || 5) - 1) * 10;
});

const moodEmoji = computed(() => getMoodEmoji(mood.value || 5));

const sortedMoodEntries = computed(() => {
  return [...moodEntries.value].sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());
});

const recentMoodEntries = computed(() => sortedMoodEntries.value.slice(0, 5));

// Chart configurations
const trendChartOptions = computed(() => ({
  chart: {
    type: "line",
    background: "transparent",
    animations: {
      enabled: true,
      easing: "easeinout",
      speed: 800,
    },
    toolbar: {
      show: false,
    },
  },
  stroke: {
    curve: "smooth",
    width: 3,
  },
  colors: ["#b085bd"],
  xaxis: {
    type: "datetime",
    labels: {
      style: {
        colors: isDarkMode.value ? "#f7f7f7" : "#333333",
      },
      datetimeFormatter: {
        year: "yyyy",
        month: "MMM",
        day: "dd",
        hour: "HH:mm",
      },
    },
  },
  yaxis: {
    min: 1,
    max: 10,
    labels: {
      style: {
        colors: isDarkMode.value ? "#f7f7f7" : "#333333",
      },
    },
  },
  tooltip: {
    theme: isDarkMode.value ? "dark" : "light",
    x: {
      format: "dd MMM yyyy HH:mm",
    },
  },
  grid: {
    borderColor: isDarkMode.value ? "#404040" : "#e0e0e0",
    padding: {
      bottom: 0,
    },
  },
  markers: {
    size: 4,
    strokeWidth: 0,
  },
}));

const trendChartSeries = computed(() => [
  {
    name: "Mood",
    data: getEntriesForTimeRange().map((entry) => ({
      x: new Date(entry.timestamp).getTime(),
      y: entry.mood,
    })),
  },
]);

const distributionChartOptions = computed(() => ({
  chart: {
    type: "bar",
    background: "transparent",
    toolbar: {
      show: false,
    },
  },
  plotOptions: {
    bar: {
      borderRadius: 4,
      horizontal: true,
      distributed: true,
      dataLabels: {
        position: "center",
      },
    },
  },
  colors: ["#ff6b6b", "#ff8c42", "#ffd93d", "#95d5b2", "#89c2d9", "#78a6c8", "#667eea", "#764ba2", "#b085bd", "#c999af"],
  xaxis: {
    categories: ["😢", "😞", "😕", "😐", "🙂", "😊", "😄", "😁", "🥳", "😍"],
    labels: {
      style: {
        colors: isDarkMode.value ? "#f7f7f7" : "#333333",
      },
    },
  },
  yaxis: {
    labels: {
      style: {
        colors: isDarkMode.value ? "#f7f7f7" : "#333333",
      },
    },
  },
  dataLabels: {
    enabled: true,
    style: {
      colors: ["#fff"],
    },
  },
  theme: {
    mode: isDarkMode.value ? "dark" : "light",
  },
}));

const distributionChartSeries = computed(() => {
  const entries = getEntriesForTimeRange();
  const distribution = new Array(10).fill(0);
  entries.forEach((entry) => {
    distribution[entry.mood - 1]++;
  });
  return [
    {
      name: "Count",
      data: distribution,
    },
  ];
});

// Helper functions
function getEntriesForTimeRange() {
  const now = new Date();
  const timeRangeMap = {
    Week: 7,
    Month: 30,
    Year: 365,
  };
  const daysAgo = timeRangeMap[selectedTimeRange.value];
  const startDate = new Date(now.setDate(now.getDate() - daysAgo));
  return moodEntries.value.filter((entry) => new Date(entry.timestamp) >= startDate);
}

function getMoodEmoji(moodValue: number): string {
  const emojis = ["😢", "😞", "😕", "😐", "🙂", "😊", "😄", "😁", "🥳", "😍"];
  return emojis[moodValue - 1] || "😐";
}

function getMoodLabel(moodValue: number): string {
  const labels = ["Very sad", "Sad", "Slightly sad", "Neutral", "Slightly happy", "Happy", "Very happy", "Extremely happy", "Ecstatic", "Blissful"];
  return labels[moodValue - 1] || "Neutral";
}

function getRelativeTime(timestamp: string): string {
  const now = new Date();
  const past = new Date(timestamp);
  const diffInSeconds = Math.floor((now.getTime() - past.getTime()) / 1000);

  if (diffInSeconds < 60) return `${diffInSeconds} seconds ago`;
  if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)} minutes ago`;
  if (diffInSeconds < 86400) return `${Math.floor(diffInSeconds / 3600)} hours ago`;
  if (diffInSeconds < 259200) return `${Math.floor(diffInSeconds / 86400)} days ago`;
  return past.toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}

const saveMood = async (): Promise<void> => {
  if (!mood.value) return;

  isSubmitting.value = true;
  const newEntry: MoodEntry = {
    mood: mood.value,
    timestamp: new Date().toISOString(),
    notes: currentNote.value.trim() || undefined,
  };

  try {
    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 500));
    moodEntries.value.unshift(newEntry);
    localStorage.setItem("moodEntries", JSON.stringify(moodEntries.value));
    currentNote.value = ""; // Clear the notes input
  } catch (error) {
    console.error("Error saving mood:", error);
    // Here you could add error handling UI feedback
  } finally {
    isSubmitting.value = false;
  }
};

const deleteMoodEntry = (index: number): void => {
  if (confirm("Are you sure you want to delete this entry?")) {
    moodEntries.value.splice(index, 1);
    localStorage.setItem("moodEntries", JSON.stringify(moodEntries.value));
  }
};

// Lifecycle hooks
onMounted(async () => {
  // Simulate a delay to show the loader
  await new Promise((resolve) => setTimeout(resolve, 300));

  try {
    const storedEntries = localStorage.getItem("moodEntries");
    if (storedEntries) {
      moodEntries.value = JSON.parse(storedEntries);
    }

    const storedDarkMode = localStorage.getItem("darkMode");
    if (storedDarkMode) {
      isDarkMode.value = JSON.parse(storedDarkMode);
    } else {
      // Check system preference
      isDarkMode.value = window.matchMedia("(prefers-color-scheme: dark)").matches;
    }
  } catch (error) {
    console.error("Error loading saved data:", error);
  } finally {
    isLoading.value = false;
  }
});

// Watchers
watch(isDarkMode, (newValue) => {
  localStorage.setItem("darkMode", JSON.stringify(newValue));
  // Force chart updates when theme changes
  trendChartOptions.value = { ...trendChartOptions.value };
  distributionChartOptions.value = { ...distributionChartOptions.value };
});
</script>

<style>
:root {
  --primary-color: #b085bd;
  --secondary-color: #c999af;
  --accent-color: #e66428;
  --background-light: #f7f7f7;
  --background-dark: #292f36;
  --text-light: #333333;
  --text-dark: #f7f7f7;
  --success-color: #4caf50;
  --error-color: #f44336;
  --chart-colors: #b085bd, #c999af, #e66428;
}

.moodmapper {
  font-family: "Fredoka", system-ui, -apple-system, sans-serif;
  min-height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
  background-color: var(--background-light);
  color: var(--text-light);
  transition: all 0.3s ease;
  position: relative;
  overflow: hidden;
  padding: 20px;
}

.dark-mode {
  background-color: var(--background-dark);
  color: var(--text-dark);
}

/* Layout Components */
.dashboard-layout {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 30px;
  max-width: 1400px;
  width: 100%;
  margin: 0 auto;
}

.content {
  background: rgba(255, 255, 255, 0.9);
  backdrop-filter: blur(10px);
  border-radius: 20px;
  padding: 30px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
  position: relative;
  z-index: 1;
  height: fit-content;
}

.dark-mode .content {
  background: rgba(41, 47, 54, 0.9);
}

/* Background Effects */
.funky-background {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(45deg, var(--primary-color) 25%, transparent 25%) -50px 0, linear-gradient(-45deg, var(--primary-color) 25%, transparent 25%) -50px 0, linear-gradient(45deg, transparent 75%, var(--primary-color) 75%), linear-gradient(-45deg, transparent 75%, var(--primary-color) 75%);
  background-size: 100px 100px;
  opacity: 0.1;
  animation: backgroundMove 20s linear infinite;
  pointer-events: none;
}

@keyframes backgroundMove {
  0% {
    background-position: -50px 0, -50px 0, 0 0, 0 0;
  }
  100% {
    background-position: 50px 0, 50px 0, 100px 100px, 100px 100px;
  }
}

/* Loading State */
.loader-container {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
  width: 100%;
  position: fixed;
  top: 0;
  left: 0;
  background: rgba(255, 255, 255, 0.8);
  backdrop-filter: blur(5px);
  z-index: 1000;
}

.dark-mode .loader-container {
  background: rgba(41, 47, 54, 0.8);
}

.loader {
  border: 5px solid var(--background-light);
  border-top: 5px solid var(--primary-color);
  border-radius: 50%;
  width: 50px;
  height: 50px;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}

/* Header Styles */
.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 30px;
}

.title {
  font-size: 3em;
  font-weight: 700;
  margin: 0;
  color: var(--primary-color);
  text-shadow: 2px 2px 0px var(--secondary-color);
}

/* Dark Mode Switch */
.switch {
  position: relative;
  display: inline-block;
  width: 60px;
  height: 34px;
}

.switch input {
  opacity: 0;
  width: 0;
  height: 0;
}

.slider {
  position: absolute;
  cursor: pointer;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: #ccc;
  transition: 0.4s;
}

.slider:before {
  position: absolute;
  content: "";
  height: 26px;
  width: 26px;
  left: 4px;
  bottom: 4px;
  background-color: white;
  transition: 0.4s;
}

input:checked + .slider {
  background-color: var(--secondary-color);
}

input:checked + .slider:before {
  transform: translateX(26px);
}

.slider.round {
  border-radius: 34px;
}

.slider.round:before {
  border-radius: 50%;
}

/* Mood Input Section */
.mood-input,
.mood-list {
  background-color: rgba(255, 255, 255, 0.7);
  padding: 25px;
  border-radius: 15px;
  margin-bottom: 30px;
  transition: all 0.3s ease;
}

.dark-mode .mood-input,
.dark-mode .mood-list {
  background-color: rgba(41, 47, 54, 0.7);
}

/* Slider Styles */
.slider-container {
  position: relative;
  height: 60px;
  margin-bottom: 20px;
}

input[type="range"] {
  -webkit-appearance: none;
  width: 100%;
  height: 10px;
  border-radius: 5px;
  background: #ddd;
  outline: none;
  opacity: 0.7;
  transition: opacity 0.2s;
}

.dark-mode input[type="range"] {
  background: #555;
}

input[type="range"]:hover {
  opacity: 1;
}

input[type="range"]::-webkit-slider-thumb {
  -webkit-appearance: none;
  width: 25px;
  height: 25px;
  border-radius: 50%;
  background: var(--accent-color);
  cursor: pointer;
  box-shadow: 0 0 5px rgba(0, 0, 0, 0.2);
}

input[type="range"]::-moz-range-thumb {
  width: 25px;
  height: 25px;
  border-radius: 50%;
  background: var(--accent-color);
  cursor: pointer;
  box-shadow: 0 0 5px rgba(0, 0, 0, 0.2);
}

/* Emoji Track */
.mood-emoji-track {
  position: relative;
  height: 40px;
  margin-top: 10px;
}

/* Button Styles */
.submit-btn {
  display: block;
  width: 100%;
  padding: 15px;
  background-color: var(--primary-color);
  color: white;
  border: none;
  border-radius: 30px;
  font-size: 1.2em;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.3s;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.submit-btn:hover:not(:disabled) {
  background-color: var(--secondary-color);
  transform: translateY(-2px);
  box-shadow: 0 6px 8px rgba(0, 0, 0, 0.15);
}

.submit-btn:disabled {
  background-color: #a0a0a0;
  cursor: not-allowed;
}

/* Analytics Section */
.analytics-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.time-range-selector {
  display: flex;
  gap: 10px;
}

.time-range-btn {
  padding: 8px 16px;
  border: 2px solid var(--primary-color);
  border-radius: 20px;
  background: transparent;
  color: var(--primary-color);
  cursor: pointer;
  transition: all 0.3s ease;
}

.time-range-btn.active {
  background: var(--primary-color);
  color: white;
}

/* Chart Containers */
.chart-container {
  background: rgba(255, 255, 255, 0.7);
  border-radius: 15px;
  padding: 20px;
  margin-bottom: 20px;
}

.dark-mode .chart-container {
  background: rgba(41, 47, 54, 0.7);
}

.chart-title {
  margin: 0 0 15px 0;
  color: var(--secondary-color);
  font-size: 1.2em;
}

/* Stats Cards */
.mood-analytics-stats {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 15px;
}

.stat-card {
  background: rgba(255, 255, 255, 0.7);
  border-radius: 15px;
  padding: 15px;
  text-align: center;
  transition: transform 0.3s ease;
}

.dark-mode .stat-card {
  background: rgba(41, 47, 54, 0.7);
}

.stat-card:hover {
  transform: translateY(-5px);
}

.stat-card h4 {
  color: var(--secondary-color);
  margin: 0 0 10px 0;
}

.stat-number {
  font-size: 1.8em;
  font-weight: bold;
  margin: 10px 0;
  color: var(--primary-color);
}

.stat-description {
  font-size: 0.9em;
  color: #888;
  margin: 0;
}

/* Recent Entries List */
.mood-list ul {
  margin: 0;
  padding: 0;
  list-style: none;
}

.mood-entry {
  display: grid;
  grid-template-columns: auto 1fr auto;
  gap: 15px;
  padding: 15px;
  border-bottom: 2px solid rgba(0, 0, 0, 0.1);
  transition: all 0.3s ease;
  min-height: 60px;
  background: inherit;
  position: relative;
  z-index: 1;
  align-items: start;
}

.mood-list ul {
  margin: 0;
  padding: 0;
  list-style: none;
  min-height: 60px;
  position: relative;
}

.dark-mode .mood-entry {
  border-bottom-color: rgba(255, 255, 255, 0.1);
}

.mood-info {
  grid-column: 1 / 3;
  display: grid;
  grid-template-columns: auto 1fr;
  gap: 15px;
  align-items: center;
}

.mood-emoji {
  font-size: 1.5em;
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 1.5em;
}

.mood-details {
  display: grid;
  gap: 4px;
}

.entry-notes {
  margin: 8px 0 0 0;
  font-size: 0.9em;
  line-height: 1.4;
  color: var(--text-light);
  background-color: rgba(255, 255, 255, 0.6);
  padding: 8px 12px;
  border-radius: 6px;
  border-left: 3px solid var(--secondary-color);
}

.dark-mode .entry-notes {
  color: var(--text-dark);
  background-color: rgba(41, 47, 54, 0.6);
}

/* Delete Button */
.delete-btn {
  grid-column: 3;
  align-self: start;
  background-color: var(--primary-color);
  color: white;
  border: none;
  border-radius: 50%;
  width: 30px;
  height: 30px;
  font-size: 1.2em;
  cursor: pointer;
  transition: all 0.3s;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0;
}

.delete-btn:hover {
  background-color: var(--error-color);
  transform: rotate(90deg);
}

/* Animations */
.list-enter-active,
.list-leave-active {
  transition: all 0.3s ease;
  max-height: 200px;
  overflow: hidden;
  opacity: 1;
}

.list-enter-from,
.list-leave-to {
  opacity: 0;
  transform: translateX(30px);
  max-height: 0;
}

.list-move {
  transition: transform 0.3s ease;
}
/* Responsive Design */
@media (max-width: 1200px) {
  .dashboard-layout {
    grid-template-columns: 1fr;
    max-width: 800px;
  }

  .mood-analytics-stats {
    grid-template-columns: repeat(3, 1fr);
  }
}

@media (max-width: 768px) {
  .moodmapper {
    padding: 10px;
  }

  .content {
    padding: 20px;
  }

  .mood-analytics-stats {
    grid-template-columns: repeat(2, 1fr);
  }

  .title {
    font-size: 2em;
  }

  .analytics-header {
    flex-direction: column;
    gap: 15px;
  }

  .time-range-selector {
    width: 100%;
    justify-content: space-between;
  }
}

@media (max-width: 480px) {
  .mood-analytics-stats {
    grid-template-columns: 1fr;
  }

  .time-range-btn {
    padding: 6px 12px;
    font-size: 0.9em;
  }

  .stat-card {
    padding: 10px;
  }

  .stat-number {
    font-size: 1.5em;
  }
}

/* Print Styles */
@media print {
  .moodmapper {
    background: none;
    padding: 0;
  }

  .mood-input,
  .time-range-selector,
  .switch,
  .funky-background {
    display: none;
  }

  .dashboard-layout {
    grid-template-columns: 1fr;
    gap: 20px;
  }

  .content {
    box-shadow: none;
    background: white;
    color: black;
    break-inside: avoid;
  }

  .chart-container {
    break-inside: avoid;
    page-break-inside: avoid;
    background: white;
  }

  .stat-card {
    page-break-inside: avoid;
    background: white;
    border: 1px solid #ddd;
  }

  .mood-entry {
    break-inside: avoid;
  }
}

/* Accessibility Enhancements */
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}

.visually-hidden {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  border: 0;
}

/* High Contrast Mode */
@media (forced-colors: active) {
  .submit-btn,
  .delete-btn,
  .time-range-btn {
    border: 2px solid currentColor;
  }

  .mood-entry {
    border-bottom: 2px solid currentColor;
  }

  .stat-card,
  .chart-container {
    border: 1px solid currentColor;
  }
}

/* Focus States */
.submit-btn:focus,
.delete-btn:focus,
.time-range-btn:focus,
input[type="range"]:focus,
textarea:focus {
  outline: 3px solid var(--accent-color);
  outline-offset: 2px;
}

/* Theme Transitions */
.theme-transition {
  transition: background-color 0.3s ease, color 0.3s ease, border-color 0.3s ease, box-shadow 0.3s ease;
}

/* Stats and Indicators */
.positive {
  color: var(--success-color);
}

.negative {
  color: var(--error-color);
}

.trend-arrow {
  font-size: 0.8em;
  margin-left: 5px;
}

/* Textarea Styles */
textarea {
  width: 100%;
  padding: 16px;
  border: 2px solid var(--primary-color);
  border-radius: 12px;
  background-color: rgba(255, 255, 255, 0.9);
  color: var(--text-light);
  font-family: inherit;
  font-size: 1em;
  line-height: 1.5;
  resize: vertical;
  min-height: 100px;
  transition: all 0.3s ease;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
}

textarea::placeholder {
  color: #999;
  opacity: 0.8;
  font-size: 0.95em;
}

textarea:hover {
  border-color: var(--secondary-color);
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
}

textarea:focus {
  outline: none;
  border-color: var(--accent-color);
  box-shadow: 0 0 0 3px rgba(230, 100, 40, 0.2);
}

.dark-mode textarea {
  background-color: rgba(41, 47, 54, 0.9);
  color: var(--text-dark);
  border-color: var(--secondary-color);
}

.dark-mode textarea::placeholder {
  color: #666;
}

/* Chart Tooltip Customization */
.apexcharts-tooltip {
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.15);
  border: none !important;
}

.dark-mode .apexcharts-tooltip {
  background: rgba(41, 47, 54, 0.95) !important;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.3);
}

/* Empty State Styles */
.empty-state {
  text-align: center;
  padding: 40px 20px;
  color: #888;
}

.dark-mode .empty-state {
  color: #666;
}
</style>
