from rag_system import RAGSystem
import os
import sys

def test():
    print("=== Testing RAG System with ChromaDB and MiniLM ===")
    
    # Create a dummy file for testing
    test_file = "test_mental_health.txt"
    with open(test_file, "w") as f:
        f.write("""
        Mental health includes our emotional, psychological, and social well-being. 
        It affects how we think, feel, and act. It also helps determine how we handle stress, 
        relate to others, and make choices. Mental health is important at every stage of life, 
        from childhood and adolescence through adulthood.
        
        Anxiety disorders are the most common mental illness in the U.S., affecting 40 million 
        adults in the United States age 18 and older, or 18.1% of the population every year.
        
        Depression (major depressive disorder) is a common and serious medical illness that 
        negatively affects how you feel, the way you think and how you act.
        """)
    print(f"Created test file: {test_file}")
            
    # Initialize
    # Using the key from app.py for testing purposes
    api_key = "AIzaSyBUn5K_Ap-gNV3Mm45FxbZq8ljbsjDPpXw"
    
    try:
        print("Step 1: Initializing RAG System...")
        rag = RAGSystem(api_key=api_key)
        
        print("Step 2: Processing file...")
        num_chunks = rag.process_file(test_file)
        print(f"Processed {num_chunks} chunks.")
        
        print("Step 3: Testing Retrieval (Vector Store)...")
        query = "What is anxiety?"
        # Access internal components to test retrieval without making API call if desired,
        # but let's try the full flow if possible, or just retrieval to be safe/fast.
        
        # Test embedding generation
        query_embedding = rag.embedding_generator.generate_embeddings([query])[0]
        print(f"Generated embedding of shape: {query_embedding.shape}")
        
        # Test search
        results = rag.vector_store.search(query_embedding)
        print(f"Search results: {len(results)} found")
        for doc, score in results:
            print(f"- Score {score:.4f}: {doc[:50]}...")
            
        if results:
            print("\n✅ SUCCESS: Embeddings and Vector Store (ChromaDB) are working correctly!")
        else:
            print("\n❌ FAILURE: No results found in vector store.")
            
    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        import traceback
        traceback.print_exc()
    finally:
        # Cleanup
        if os.path.exists(test_file):
            os.remove(test_file)
            print(f"Removed test file: {test_file}")

if __name__ == "__main__":
    test()
