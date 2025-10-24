import streamlit as st
import requests
import time
import pandas as pd


BLYNK_TOKEN = "YgVBQ9U8QkyoZ4jsPX7CTFqf52GCik_a"

def get_blynk_value(pin):
    url = f"https://blynk.cloud/external/api/get?token={BLYNK_TOKEN}&pin={pin}"
    try:
        response = requests.get(url, timeout=5)
        return float(response.text)
    except:
        return 0.0

def set_blynk_value(pin, value):
    url = f"https://blynk.cloud/external/api/update?token={BLYNK_TOKEN}&{pin}={value}"
    try:
        requests.get(url, timeout=5)
    except:
        pass

st.set_page_config(page_title="AI EnergySaver Dashboard", layout="wide")
st.title("⚙️ EnergySaver AI Dashboard")
st.markdown("### Real-time Monitoring | AI Prediction | Smart Reset")


if st.button("🔁 Reset System (Manual)"):
    set_blynk_value("V0", 0)
    set_blynk_value("V1", 0)
    st.success("System has been reset successfully in Blynk!")



water_flow = get_blynk_value("V1")
current_value = get_blynk_value("V0")

col1, col2 = st.columns(2)
with col1:
    st.subheader("💧 Water Flow")
    st.metric(label="Total Water (L)", value=f"{water_flow:.2f}")

with col2:
    st.subheader("⚡ Current Sensor")
    st.metric(label="Current (mA RMS)", value=f"{current_value:.2f}")

if "data" not in st.session_state:
    st.session_state.data = []

st.session_state.data.append({
    "time": time.strftime("%H:%M:%S"),
    "water": water_flow,
    "current": current_value
})

df = pd.DataFrame(st.session_state.data)
st.line_chart(df.set_index("time"))


st.divider()
st.subheader("🧠 AI Prediction & Alerts")

status = "✅ Normal Consumption"
suggestion = "System running efficiently."

if water_flow > 100:
    status = "⚠️ High Water Usage"
    suggestion = "Possible leak or open tap — check flow immediately."
elif current_value > 2000:
    status = "⚠️ High Power Draw"
    suggestion = "Turn off unused devices or check for overload."
elif current_value == 0:
    status = "🔁 Auto Reset Triggered"
    suggestion = "Current dropped to 0 — auto-resetting system."
    set_blynk_value("V0", 0)
    set_blynk_value("V1", 0)
    st.info("Auto-reset performed because current = 0.")

st.write(f"**Status:** {status}")
st.write(f"**AI Suggestion:** {suggestion}")

st.divider()
st.subheader("📊 System Insights")

col3, col4, col5 = st.columns(3)
avg_current = df["current"].mean()
avg_water = df["water"].mean()

col3.metric("🔋 Avg Current (mA)", f"{avg_current:.2f}")
col4.metric("🚰 Avg Water Flow (L)", f"{avg_water:.2f}")
col5.metric("📅 Data Points Logged", len(df))


time.sleep(2)
st.rerun()
