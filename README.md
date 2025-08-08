# SIKKA (سكة) – Public Transportation Navigator for Sudan

[![Flutter](https://img.shields.io/badge/Flutter-Framework-blue)](https://flutter.dev/)
[![Backend](https://img.shields.io/badge/Backend-GraphHopper-green)](https://www.graphhopper.com/)
[![License](https://img.shields.io/badge/License-MIT-lightgrey)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Production--Ready-success)]()

**SIKKA (سكة)** is a cross-platform mobile application built for the **Code for Sudan** competition.  
It’s designed to provide **efficient, multi-modal navigation** across Sudan’s public transport network — combining walking routes with bus and minibus connections in a single, intuitive interface.

---

## Features

### 1. Interactive Map & Real-Time Navigation
- **OpenStreetMap Integration** for detailed mapping.
- **User Location Detection** with permission-based GPS access.
- **Tap-to-Select Origin/Destination** directly from the map.
- **Robust Search** using Nominatim geocoding.

### 2. Advanced Multi-Modal Route Planning
- **Optimized Routing** combining walking + public transport.
- **Custom Backend Integration** tuned for Sudan’s transport network.
- **Route Visualization**:
  - Distinct styling for walking vs. transit segments.
  - Color-coded public transport routes.
  - Clear markers for start, end, and key stops.

### 3. Intuitive UI/UX
- **Animated Landing Screen** with SIKKA branding.
- **SlidingUpPanel Interface** for searching and viewing trips without losing map context.
- **Detailed Trip Breakdowns**:
  - Summary card (duration, distance, transfers).
  - Step-by-step walking and transit instructions.
- **Error Handling & Feedback** for network and server downtime.

### 4. Localization & Cultural Relevance
- Arabic-first naming: *سكة* means “path/road.”
- Automatic translation of backend route IDs to **official Arabic route names**.
- Custom branding, icons, and splash screen.

---

## Backend & Data Pipeline

### 1. Custom Routing Engine
- Powered by **GraphHopper API**.
- Sudan-specific **walk.pbf** map data.
- Hosted API: [`https://sikka-api.onrender.com`](https://sikka-api.onrender.com).

### 2. GTFS Data Generation (No Official Dataset Required)
- Manual tracing of routes for accuracy.
- Conversion of GPX data to GTFS using a **custom Python script**.
- Automatic:
  - Bus stop creation.
  - Travel & waiting time estimation.
  - Transfer point identification.
- Fully integrated into GraphHopper for multi-modal routing.

---

## Tech Stack

| Layer         | Technology                                   |
|---------------|----------------------------------------------|
| Frontend      | Flutter, Dart                                |
| Mapping       | OpenStreetMap, Nominatim Geocoding           |
| Backend       | Python, GraphHopper Routing Engine           |
| Data Handling | Custom GPX → GTFS Pipeline                   |
| Hosting       | Public API Deployment                        |

---

## Installation

### Frontend (Flutter)
```bash
git clone https://github.com/yourusername/sikka.git
cd sikka/frontend
flutter pub get
flutter run
