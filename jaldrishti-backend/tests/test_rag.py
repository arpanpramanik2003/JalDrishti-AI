import sys
import os

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.services.rag_service import RAGService

def main():
    print("=" * 65)
    print(" 🚀 TESTING GROQ-POWERED RAG AGRI-CHATBOT")
    print("=" * 65)

    rag = RAGService()

    # Query 1: English Test
    q1 = "What medicine should I apply for Yellow Stem Borer in rice?"
    print(f"\n❓ Question 1 (English): {q1}")
    ans1 = rag.answer_farmer_query(q1, language="English")
    print(f"🤖 Groq Response:\n{ans1}")

    # Query 2: Bengali Multilingual Test
    q2 = "ধান গাছে বাদামী শোষক পোকা (BPH) হলে কী ওষুধ দেব?"
    print(f"\n❓ Question 2 (Bengali): {q2}")
    ans2 = rag.answer_farmer_query(q2, language="Bengali")
    print(f"🤖 Groq Response:\n{ans2}")

    print("\n" + "=" * 65)
    print(" RAG CHATBOT TEST COMPLETED SUCCESSFULLY!")
    print("=" * 65)

if __name__ == "__main__":
    main()