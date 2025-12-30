import chromadb
import numpy as np
from typing import List, Tuple
import uuid

class VectorStore:
    """Vector store using ChromaDB for persistence"""
    
    def __init__(self, collection_name: str = "mental_health_docs"):
        print("Initializing ChromaDB vector store...")
        # Use a local folder for persistence to avoid memory limits
        self.client = chromadb.PersistentClient(path="./chroma_db")
        self.collection_name = collection_name
        
        # Reset collection to start fresh (mimic in-memory behavior)
        try:
            self.client.delete_collection(collection_name)
            print(f"Deleted existing collection: {collection_name}")
        except Exception:
            pass # Collection didn't exist or couldn't be deleted
            
        self.collection = self.client.create_collection(name=collection_name)
        print(f"ChromaDB initialized with collection: {collection_name}")
    
    def add_documents(self, documents: List[str], embeddings: List[np.ndarray]):
        """Add documents and their embeddings to the store"""
        if not documents:
            return
            
        print(f"VECTOR STORE: Adding {len(documents)} documents to ChromaDB...")
        
        # Generate IDs
        ids = [str(uuid.uuid4()) for _ in documents]
        
        # Convert numpy arrays to lists for ChromaDB
        embeddings_list = [emb.tolist() if isinstance(emb, np.ndarray) else emb for emb in embeddings]
        
        # Add to collection
        self.collection.add(
            documents=documents,
            embeddings=embeddings_list,
            ids=ids
        )
        print("VECTOR STORE: Documents added successfully")
    
    def search(self, query_embedding: np.ndarray, top_k: int = 3) -> List[Tuple[str, float]]:
        """Search for most similar documents"""
        # Convert query embedding to list
        query_emb_list = query_embedding.tolist() if isinstance(query_embedding, np.ndarray) else query_embedding
        
        # Query ChromaDB
        results = self.collection.query(
            query_embeddings=[query_emb_list],
            n_results=top_k
        )
        
        if not results['documents']:
            return []
            
        docs = results['documents'][0]
        # Chroma returns distances. We'll just return the docs and distances.
        # Note: The original code expected (doc, score). 
        # We'll return (doc, distance) here. The RAG system doesn't use the score for logic, just context building.
        distances = results['distances'][0] if 'distances' in results else [0.0] * len(docs)
        
        return list(zip(docs, distances))
    
    def clear(self):
        """Clear the vector store"""
        print("VECTOR STORE: Clearing collection...")
        try:
            self.client.delete_collection(self.collection_name)
            self.collection = self.client.create_collection(name=self.collection_name)
            print("VECTOR STORE: Collection cleared")
        except Exception as e:
            print(f"VECTOR STORE ERROR: {e}")