from google import genai
import os
import json
from dotenv import load_dotenv

load_dotenv()

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))


def analyze_receipt(receipt_text):

    prompt = f"""
    Analyze this receipt.

    Return ONLY valid JSON.

    Format:
    {{
      "store": "",
      "items": [
        {{
          "name": "",
          "price": 0,
          "category": ""
        }}
      ],
      "total": 0,
      "insights": []
    }}

    Receipt:
    {receipt_text}
    """

    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=prompt
    )

    raw_text = response.text

    # CLEAN MARKDOWN JSON
    cleaned = raw_text.replace("```json", "")
    cleaned = cleaned.replace("```", "")
    cleaned = cleaned.strip()

    # CONVERT TO PYTHON DICTIONARY
    data = json.loads(cleaned)

    return data