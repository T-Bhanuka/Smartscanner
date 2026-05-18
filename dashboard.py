import streamlit as st
import pandas as pd
import sqlite3

st.title("🧾 Receipt Intelligence Dashboard")

# DATABASE CONNECTION
conn = sqlite3.connect("receipts.db")

df = pd.read_sql_query(
    "SELECT * FROM receipts",
    conn
)

conn.close()

# SHOW TABLE
st.subheader("📋 Receipt Records")
st.dataframe(df)

# TOTAL SPENDING
st.subheader("💰 Total Spending")

total_spend = df["total"].sum()

st.metric("Total Spend", total_spend)

# HIGHEST SPENDING
highest = df["total"].max()

st.metric("Highest Expense", highest)

# AVERAGE SPENDING
average = df["total"].mean()

st.metric("Average Spend", round(average, 2))

# BAR CHART
st.subheader("📊 Spending Chart")

st.bar_chart(df["total"])

# AI INSIGHTS
st.subheader("🧠 AI Insights")

for insight in df["insights"]:
    st.write("👉", insight)



df["date"] = pd.to_datetime(df["date"])
df["month"] = df["date"].dt.to_period("M")

monthly = df.groupby("month")["total"].sum()

st.subheader("📈 Monthly Spending Trend")

st.line_chart(monthly)

st.bar_chart(monthly)

if len(monthly) > 1:
    if monthly.iloc[-1] > monthly.iloc[-2]:
        st.warning("⚠️ Spending is increasing this month")
    else:
        st.success("✅ Spending is stable or decreasing")