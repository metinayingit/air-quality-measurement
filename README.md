# 🌿 Air Quality Measurement

This project involves measuring air quality using the MQ-135 sensor and transmitting the collected data to Firebase. The data is then retrieved from Firebase and displayed on a mobile application. The steps are as follows:

## 📋 Steps

### 1. 🛠️ Sensor Setup
The MQ-135 sensor, connected to an ADC pin on a microcontroller, measures the air quality.

### 2. 🌐 Network Connection
The microcontroller connects to a Wi-Fi network to enable internet access.

### 3. ⏰ Time Synchronization
The Real-Time Clock (RTC) on the microcontroller is synchronized with an NTP server to ensure accurate timestamps for the sensor readings.

### 4. 📊 Data Collection
The sensor readings are converted into air quality percentages.

### 5. 🚀 Data Transmission
The air quality data, along with the timestamp, minimum and maximum recorded values are sent to Firebase using HTTP requests.

### 6. 🔄 Data Retrieval
The latest air quality data, including the last five readings and the recorded minimum and maximum values, are retrieved from Firebase.

### 7. 📱 Mobile Application
The retrieved data is displayed on a mobile application, providing real-time air quality monitoring.

## 📌 Summary
The system ensures continuous monitoring and updating of air quality data, allowing users to stay informed about the air quality in their environment through a user-friendly mobile interface.
