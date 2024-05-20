from machine import Pin, ADC, UART, RTC
import utime
import urequests as requests
import json
import network
import ntptime

ssid = 'wifi'
password = '12345'

wlan = network.WLAN(network.STA_IF)
wlan.active(True)

if not wlan.isconnected():
    print('Connecting to the Internet...')
    wlan.connect(ssid, password)
    while not wlan.isconnected():
        utime.sleep(1)

print('Network config:', wlan.ifconfig())

rtc = RTC()
ntptime.settime()

firebase_url = 'url'
api_key = 'key'

adc = ADC(Pin(28))
uart = UART(0, baudrate=9600, tx=Pin(12), rx=Pin(13))

def datetime_to_timestamp(dt):
    year, month, day, _, hour, minute, second, _ = dt
    tm = (year, month, day, hour, minute, second, 0, 0)
    timestamp = utime.mktime(tm)
    return timestamp

last_five_readings = []

def send_data_to_firebase(sensor_data, last_five):
    endpoint = f"{firebase_url}/sensor1.json?auth={api_key}"
    headers = {"Content-Type": "application/json"}
    sensor_data["last5"] = last_five
    response = requests.put(endpoint, headers=headers, data=json.dumps(sensor_data))
    response.close()

def read_sensor():
    reading = adc.read_u16()
    voltage = 100 - ((reading / 65535.0) * 3.3) * 100
    return voltage

def convert_to_decimal(dms_val):
    try:
        d, m = dms_val[:2], dms_val[2:]
        return str(int(d) + float(m) / 60)
    except ValueError:
        return "Invalid format."

def get_last_five_readings_from_firebase():
    try:
        response = requests.get(f"{firebase_url}/sensor1/last5.json?auth={api_key}")
        data = response.json()
        if not data:
            return []
        return data
    except Exception as e:
        print("Error fetching last five readings from Firebase:", e)
        return []

def get_min_max_values_from_firebase():
    try:
        response = requests.get(f"{firebase_url}/sensor1.json?auth={api_key}")
        data = response.json()
        min_voltage = data.get("low", 100)
        max_voltage = data.get("high", 0)
        return min_voltage, max_voltage
    except Exception as e:
        print("Error getting values from Firebase:", e)
        return 100, 0

min_voltage, max_voltage = get_min_max_values_from_firebase()
last_five_readings = get_last_five_readings_from_firebase()

while True:
    sensor_voltage = read_sensor()
    print(f"Air quality percentage: {sensor_voltage}%")
    
    if sensor_voltage > max_voltage:
        max_voltage = sensor_voltage
    if sensor_voltage < min_voltage:
        min_voltage = sensor_voltage
    
    last_five_readings.append({'time': int(datetime_to_timestamp(rtc.datetime())), 'quality': sensor_voltage})
    if len(last_five_readings) > 5:
        last_five_readings.pop(0)
    
    sensor_data = {'time': int(datetime_to_timestamp(rtc.datetime())), 'quality': sensor_voltage, "latitude": "37.8", "longitude": "32.4", "low": min_voltage, "high": max_voltage}
    send_data_to_firebase(sensor_data, last_five_readings)
    
    min_voltage, max_voltage = get_min_max_values_from_firebase()
    
    utime.sleep(1)