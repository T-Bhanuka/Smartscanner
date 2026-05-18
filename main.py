from ocr import extract_text
from agent import analyze_receipt
from database import save_receipt

# OCR extracts text
receipt_text = extract_text("receipt.jpg")

print("OCR TEXT:")
print(receipt_text)

# Gemini AI analyzes
result = analyze_receipt(receipt_text)

print(result)

# Save to DB
save_receipt(result)

print("Saved successfully!")
print(type(result))
print(result)