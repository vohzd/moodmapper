<template>
  <main class="moodmapper" :class="{ 'dark-mode': isDarkMode }">
    <div class="funky-background"></div>
    <div v-if="isLoading" class="loader-container">
      <div class="loader"></div>
    </div>
    <div v-else class="content">
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
          <input type="range" id="mood" name="mood" step="1" min="1" max="10" v-model="mood" />
          <div class="mood-emoji-track">
            <div class="mood-emoji" :style="{ left: `${emojiPosition}%` }">
              {{ moodEmoji }}
            </div>
          </div>
        </div>
        <button class="submit-btn" @click="saveMood" :disabled="isSubmitting">
          {{ isSubmitting ? "Saving..." : "Capture Mood" }}
        </button>
      </div>

      <div class="mood-list">
        <h2>Mood Journal</h2>
        <transition-group name="list" tag="ul">
          <li v-for="(entry, index) in sortedMoodEntries" :key="entry.timestamp" class="mood-entry">
            <div class="mood-info">
              <span class="mood-emoji">{{ getMoodEmoji(entry.mood) }}</span>
              <span class="mood-details">
                <strong>Mood: {{ entry.mood }}</strong>
                <br />
                <small>{{ getRelativeTime(entry.timestamp) }}</small>
              </span>
            </div>
            <button class="delete-btn" @click="deleteMoodEntry(index)" aria-label="Delete entry">&times;</button>
          </li>
        </transition-group>
      </div>
    </div>
  </main>
</template>

<script setup lang="ts">
import { computed, onMounted, ref, watch } from "vue";

interface MoodEntry {
  mood: number;
  timestamp: string;
}

const mood = defineModel<number>();
mood.value = 5; // Start at neutral mood

const moodEntries = ref<MoodEntry[]>([]);
const isSubmitting = ref(false);
const isDarkMode = ref(false);
const isLoading = ref(true);

const emojiPosition = computed(() => {
  return (mood.value - 1) * 10; // Precisely 10% increments
});

const moodEmoji = computed(() => getMoodEmoji(mood.value));

const sortedMoodEntries = computed(() => {
  return [...moodEntries.value].sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());
});

const saveMood = async (): Promise<void> => {
  isSubmitting.value = true;
  const newEntry: MoodEntry = {
    mood: mood.value,
    timestamp: new Date().toISOString(),
  };
  // Simulate API call
  await new Promise((resolve) => setTimeout(resolve, 500));
  moodEntries.value.unshift(newEntry);
  localStorage.setItem("moodEntries", JSON.stringify(moodEntries.value));
  isSubmitting.value = false;
};

const deleteMoodEntry = (index: number): void => {
  moodEntries.value.splice(index, 1);
  localStorage.setItem("moodEntries", JSON.stringify(moodEntries.value));
};

const getRelativeTime = (timestamp: string): string => {
  const now = new Date();
  const past = new Date(timestamp);
  const diffInSeconds = Math.floor((now.getTime() - past.getTime()) / 1000);

  if (diffInSeconds < 60) return `${diffInSeconds} seconds ago`;
  if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)} minutes ago`;
  if (diffInSeconds < 86400) return `${Math.floor(diffInSeconds / 3600)} hours ago`;
  if (diffInSeconds < 259200) return `${Math.floor(diffInSeconds / 86400)} days ago`;
  return past.toLocaleDateString("en-US", { year: "numeric", month: "short", day: "numeric" });
};

const getMoodEmoji = (moodValue: number): string => {
  const emojis = ["😢", "😞", "😕", "😐", "🙂", "😊", "😄", "😁", "🥳", "😍"];
  return emojis[moodValue - 1] || "😐";
};

onMounted(async () => {
  // Simulate a delay to show the loader
  await new Promise((resolve) => setTimeout(resolve, 300));

  const storedEntries = localStorage.getItem("moodEntries");
  if (storedEntries) {
    moodEntries.value = JSON.parse(storedEntries);
  }
  const storedDarkMode = localStorage.getItem("darkMode");
  if (storedDarkMode) {
    isDarkMode.value = JSON.parse(storedDarkMode);
  }
  isLoading.value = false;
});

watch(isDarkMode, (newValue) => {
  localStorage.setItem("darkMode", JSON.stringify(newValue));
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
}

.moodmapper {
  font-family: "Fredoka", sans-serif;
  min-height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
  background-color: var(--background-light);
  color: var(--text-light);
  transition: all 0.3s ease;
  position: relative;
  overflow: hidden;
}

.dark-mode {
  background-color: var(--background-dark);
  color: var(--text-dark);
}

ul {
  margin: 0;
  padding: 0;
}

.funky-background {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(45deg, var(--primary-color) 25%, transparent 25%) -50px 0, linear-gradient(-45deg, var(--primary-color) 25%, transparent 25%) -50px 0, linear-gradient(45deg, transparent 75%, var(--primary-color) 75%), linear-gradient(-45deg, transparent 75%, var(--primary-color) 75%);
  background-size: 100px 100px;
  opacity: 0.1;
  animation: backgroundMove 20s linear infinite;
}

@keyframes backgroundMove {
  0% {
    background-position: -50px 0, -50px 0, 0 0, 0 0;
  }
  100% {
    background-position: 50px 0, 50px 0, 100px 100px, 100px 100px;
  }
}

.content {
  background: rgba(255, 255, 255, 0.9);
  backdrop-filter: blur(10px);
  border-radius: 20px;
  padding: 30px;
  max-width: 600px;
  width: 100%;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
  position: relative;
  z-index: 1;
}

.dark-mode .content {
  background: rgba(41, 47, 54, 0.9);
}

.loader-container {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
  width: 100%;
  position: absolute;
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

.dark-mode .loader {
  border-color: var(--background-dark);
  border-top-color: var(--primary-color);
}

@keyframes spin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}

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

h3,
h2 {
  color: var(--secondary-color);
  font-size: 1.8em;
  margin-top: 0;
  margin-bottom: 20px;
}

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
  appearance: none;
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

.mood-emoji-track {
  position: relative;
  height: 40px;
  margin-top: 10px;
}

.mood-emoji {
  position: absolute;
  top: 0;
  font-size: 2em;
  transition: left 0.3s ease;
  transform: translateX(-50%);
}

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

.mood-entry {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 15px;
  border-bottom: 2px solid rgba(0, 0, 0, 0.1);
  transition: all 0.3s;
}

.dark-mode .mood-entry {
  border-bottom-color: rgba(255, 255, 255, 0.1);
}

.mood-entry:last-child {
  border-bottom: none;
}

.mood-entry:hover {
  background-color: rgba(255, 255, 255, 0.5);
  transform: scale(1.02);
}

.dark-mode .mood-entry:hover {
  background-color: rgba(0, 0, 0, 0.2);
}

.mood-info {
  display: flex;
  align-items: center;
}

.mood-info .mood-emoji {
  font-size: 1.8em;
  margin-right: 15px;
  position: static;
  transform: none;
}

.mood-details strong {
  color: var(--secondary-color);
}

.mood-details small {
  color: #888;
}

.delete-btn {
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
}

.delete-btn:hover {
  background-color: #ff4757;
  transform: rotate(90deg);
}

.list-enter-active,
.list-leave-active {
  transition: all 0.5s ease;
}
.list-enter-from,
.list-leave-to {
  opacity: 0;
  transform: translateX(30px);
}
</style>
