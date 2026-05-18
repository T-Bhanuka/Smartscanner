from database import save_receipt

test_data = {
    "store": "KFC",
    "total": 1500,
    "insights": ["High food spending"]
}

save_receipt(test_data)

print("Saved successfully!")