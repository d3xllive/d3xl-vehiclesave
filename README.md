<div align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=red&height=200&section=header&text=d3xl-vehiclesave&fontSize=70&animation=fadeIn&fontColor=ffffff" />

  <p align="center">
    <img src="https://img.shields.io/badge/Version-1.0.0-red?style=for-the-badge" />
    <img src="https://img.shields.io/badge/Framework-QBCore-black?style=for-the-badge" />
    <img src="https://img.shields.io/badge/Optimized-0.00ms-green?style=for-the-badge" />
  </p>

  <h3>🚀 Advanced & Lightweight Vehicle State Saver</h3>
  <p>An optimized solution for FiveM servers to persist vehicle data across sessions.</p>
</div>

---

### 📖 Description
**d3xl-vehiclesave** is a high-performance script designed for the **QBCore** framework. It ensures that every detail of a player's vehicle—from engine health to the smallest visual modification—is saved securely in JSON format. 

It uses **ox_lib** for maximum efficiency and provides a seamless experience for both developers and players.

---

### ✨ Key Features
- 🛠️ **Deep State Saving:** Saves body health, engine health, fuel level, dirt level, and more.
- 🎨 **Visual Mods:** Full support for all GTA V vehicle modifications (colors, neons, xenon, wheels, etc.).
- ⚡ **Ultra Optimized:** Runs at **0.00ms** on idle.
- 📂 **JSON Storage:** Fast data handling without heavy SQL queries for every save.
- ⚙️ **Fully Configurable:** Easily adjust save intervals and ignored vehicle models.
- 🔔 **Clean Notifications:** Integrated chat notifications for saving status.

---

### 🛠️ Installation
1. **Download** the repository.
2. **Extract** the folder into your `resources` directory.
3. **Rename** the folder to `d3xl-vehiclesave` (if it has a "-main" suffix).
4. **Add** the following line to your `server.cfg`:
   ```cfg
   ensure d3xl-vehiclesave
