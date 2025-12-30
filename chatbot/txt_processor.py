from typing import List

class TXTProcessor:
    """Handles TXT file text extraction and chunking"""
    
    def __init__(self, chunk_size: int = 1000, chunk_overlap: int = 200):
        self.chunk_size = chunk_size
        self.chunk_overlap = chunk_overlap
    
    def extract_text(self, txt_path: str) -> str:
        """Extract all text from TXT file"""
        try:
            with open(txt_path, 'r', encoding='utf-8') as file:
                text = file.read()
            return text
        except UnicodeDecodeError:
            # Try with different encoding if UTF-8 fails
            with open(txt_path, 'r', encoding='latin-1') as file:
                text = file.read()
            return text
    
    def chunk_text(self, text: str) -> List[str]:
        """Split text into overlapping chunks"""
        chunks = []
        start = 0
        text_length = len(text)
        
        while start < text_length:
            end = start + self.chunk_size
            
            # If not at the end, try to break at a sentence or word boundary
            if end < text_length:
                # Look for period, question mark, or exclamation point
                for delimiter in ['. ', '? ', '! ', '\n\n', '\n', ' ']:
                    last_delimiter = text.rfind(delimiter, start, end)
                    # Ensure we don't cut the chunk too small (must be larger than overlap to advance)
                    if last_delimiter != -1 and (last_delimiter + len(delimiter)) > (start + self.chunk_overlap):
                        end = last_delimiter + len(delimiter)
                        break
            
            chunk = text[start:end].strip()
            if chunk:
                chunks.append(chunk)
            
            start = end - self.chunk_overlap
        
        return chunks
    
    def extract_chunks(self, txt_path: str) -> List[str]:
        """Extract and chunk TXT text"""
        text = self.extract_text(txt_path)
        chunks = self.chunk_text(text)
        return chunks