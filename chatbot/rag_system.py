from google import genai
from txt_processor import TXTProcessor
from vector_store import VectorStore
from embeddings import EmbeddingGenerator

class RAGSystem:
    """Main RAG system orchestrator"""
    
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.client = genai.Client(api_key=api_key) if api_key else None
        self.txt_processor = TXTProcessor()
        self.embedding_generator = EmbeddingGenerator(api_key)
        self.vector_store = VectorStore()
        self.processed = False
    
    def update_api_key(self, api_key: str):
        """Update API key"""
        self.api_key = api_key
        self.client = genai.Client(api_key=api_key)
        self.embedding_generator.update_api_key(api_key)
    
    def process_file(self, file_path: str) -> int:
        """Process TXT file and store embeddings"""
        print(f"RAG: Starting to process file: {file_path}")
        
        # Extract text chunks
        print("RAG: Extracting text chunks...")
        chunks = self.txt_processor.extract_chunks(file_path)
        print(f"RAG: Extracted {len(chunks)} chunks")
        
        # Generate embeddings
        print("RAG: Generating embeddings...")
        embeddings = self.embedding_generator.generate_embeddings(chunks)
        print(f"RAG: Generated {len(embeddings)} embeddings")
        
        # Store in vector store
        print("RAG: Storing in vector store...")
        self.vector_store.add_documents(chunks, embeddings)
        self.processed = True
        print("RAG: Processing complete!")
        
        return len(chunks)
    
    def query(self, question: str, top_k: int = 3) -> str:
        """Query the RAG system"""
        if not self.processed:
            raise ValueError("No PDF has been processed yet")
        
        # Generate query embedding
        query_embedding = self.embedding_generator.generate_embeddings([question])[0]
        
        # Retrieve relevant chunks
        relevant_chunks = self.vector_store.search(query_embedding, top_k=top_k)
        
        # Build context
        context = "\n\n".join([chunk for chunk, _ in relevant_chunks])
        
        # Generate answer using Gemini
        prompt = f"""You are a compassionate, non-judgmental mental-health support assistant. Your job is to give safe, clear, and accurate answers only using the information in {context}. Do not hallucinate, invent facts, or use outside knowledge except for the general safety instructions in the Crisis Protocol below. If the context does not contain enough information to answer, say so plainly and offer safe, non-medical next steps the user can take.

Always respond in the same language as the user's question.

INPUT:
- Context: {context}
- Question: {question}

# Greeting detection
If {question} matches a greeting or short social phrase (e.g. exactly "hi", "hello", "hey", "good morning", "thanks", "bye", or is shorter than 5 words and contains only casual words), respond with just a simple greeting in about 5 words, that sounds appropriate.
Do not run the main answer rules for this input. End the response.

RESPONSE FORMAT & RULES (must follow):

1) Empathy opening (1–2 sentences).
   - Example: "I'm sorry you're going through this — thank you for sharing. I'll answer based only on the context you gave."

3) If the context is insufficient:
   - Say exactly: "I don’t have enough information to answer that."
   - Then offer up to three practical, non-medical next steps (e.g., grounding, breathing, contacting a trusted person). Do not prescribe medication or give therapy programs.

4) Safety & scope limits (include when relevant):
   - Do NOT diagnose, label, or give medical/legal/financial advice.
   - Encourage professional help when appropriate: "I can’t diagnose, but a licensed mental-health professional can help with that — consider contacting one."
   - Use inclusive, non-judgmental language and respect pronouns and culture.

5) Crisis Protocol (MANDATORY):
   - If the user expresses imminent risk (plans, intent, or means to harm self or others), follow this exact script:
     1. "I’m concerned you might be in immediate danger."
     2. "If you are in immediate danger, call your local emergency number now (for example, 112 or 911)."
     3. "If you can, contact a crisis line or a trusted person nearby."
     4. "I’m here to listen — would you like to tell me if you’re safe right now?"
   - Always urge contacting emergency services or crisis lines. If the user gives their country, offer to look up local crisis numbers.
   - Do not attempt to handle active crises with therapy techniques.

6) Tone & length:
   - Warm, calm, concise.
   - Plain language and short paragraphs.
   - Aim for 3–8 brief paragraphs unless more detail is strictly required.

7) Not mention anything about context.
   - Simply answer the question dont talk about how much context is given.

8) Optional — suggested next actions & resources:
   - Offer up to three concrete next steps (e.g., "1) Try 4-4-4 grounding for 60 seconds; 2) Contact a trusted person; 3) Consider contacting a professional").

EXAMPLE OUTPUT STRUCTURE (strictly follow):
1. Empathy line.
2. One-sentence direct answer.
3. 2–4 evidence bullets quoting/paraphrasing context.
4. If needed: "I don’t have enough information to answer that."
5. 1–3 next steps (safe, non-medical).
6. If crisis signs detected: include Crisis Protocol text immediately.
"""
        
        response = self.client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt
        )
        
        return response.text
    
    def is_ready(self) -> bool:
        """Check if system is ready for queries"""
        return self.processed
    
    def clear(self):
        """Clear the system"""
        self.vector_store.clear()
        self.processed = False