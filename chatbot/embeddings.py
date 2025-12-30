from typing import List
import numpy as np
from sentence_transformers import SentenceTransformer

class EmbeddingGenerator:
    """Generates embeddings using Sentence Transformers (all-MiniLM-L6-v2)"""
    
    def __init__(self, api_key: str = None):
        print("Initializing Sentence Transformer model...")
        # Load the model - this will download it on first run
        self.model = SentenceTransformer("paraphrase-multilingual-MiniLM-L12-v2")
        print("Sentence Transformer model initialized!")
    
    def update_api_key(self, api_key: str):
        """Update API key (not needed for local embeddings)"""
        pass
    
    def generate_embeddings(self, texts: List[str]) -> List[np.ndarray]:
        """Generate embeddings for a list of texts"""
        print(f"EMBEDDINGS: Generating embeddings for {len(texts)} texts...")
        try:
            # Generate embeddings
            # convert_to_numpy=True is default, but being explicit
            embeddings = self.model.encode(texts, convert_to_numpy=True)
            print(f"EMBEDDINGS: Successfully generated {len(embeddings)} embeddings")
            return list(embeddings)
        except Exception as e:
            print(f"EMBEDDINGS ERROR: {e}")
            import traceback
            traceback.print_exc()
            # Return empty embeddings in case of error (fallback)
            # 384 is the dimension for all-MiniLM-L6-v2
            return [np.zeros(384) for _ in texts]