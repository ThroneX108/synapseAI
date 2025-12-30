import gradio as gr
import os
from rag_system import RAGSystem

# ====================================================================================
# PASTE YOUR API KEY HERE (between the quotes)
# ====================================================================================
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")  # <-- PASTE YOUR API KEY HERE
# ====================================================================================

# ====================================================================================
# UPLOAD YOUR TXT FILE PATH HERE (the TXT file that will be pre-loaded)
# ====================================================================================
FILE_PATH = "Mental_Health_Guide.txt"  # <-- PUT YOUR TXT FILE NAME HERE (must be in same folder)
# ====================================================================================

# Global variable to hold RAG system
rag = None
startup_message = ""

def initialize_system():
    """Initialize the RAG system once"""
    global rag, startup_message
    
    print("=== INITIALIZATION STARTED ===")
    
    if rag is not None:
        print("RAG already initialized, skipping...")
        return  # Already initialized
    
    try:
        print("Step 1: Creating RAG system...")
        rag = RAGSystem(api_key=GEMINI_API_KEY)
        print("Step 2: RAG system object created!")
        
        # Process the file at startup
        print(f"Step 3: Checking for TXT file: {FILE_PATH}")
        if os.path.exists(FILE_PATH):
            print(f"Step 4: TXT file found! Processing...")
            num_chunks = rag.process_file(FILE_PATH)
            startup_message = f"✅ Mental health resources loaded successfully! Created {num_chunks} knowledge chunks. Ready to help!"
            print(f"Step 5: SUCCESS - {startup_message}")
        else:
            startup_message = f"⚠️ Resource file '{FILE_PATH}' not found in directory."
            print(f"Step 5: FAILED - {startup_message}")
            print(f"Current directory contents: {os.listdir('.')}")
    except Exception as e:
        startup_message = f"❌ Error during initialization: {str(e)}"
        print(f"ERROR: {startup_message}")
        import traceback
        traceback.print_exc()
    
    print("=== INITIALIZATION COMPLETE ===")

def answer_question(question):
    """Answer question using RAG - Simple input/output"""
    print(f"\n=== QUESTION RECEIVED: {question} ===")
    
    # Initialize if not already done
    if rag is None:
        print("RAG is None, calling initialize_system()...")
        initialize_system()
    
    if not question or question.strip() == "":
        return "Please enter a question."
    
    print(f"Checking if RAG is ready... rag={rag}, is_ready={rag.is_ready() if rag else 'N/A'}")
    
    if rag is None or not rag.is_ready():
        return f"⚠️ System not ready. Status: {startup_message}"
    
    try:
        print("Querying RAG system...")
        answer = rag.query(question)
        print("Answer generated successfully!")
        return answer
    except Exception as e:
        error_msg = f"❌ Error: {str(e)}"
        print(error_msg)
        import traceback
        traceback.print_exc()
        return error_msg

# Create simple Gradio interface
with gr.Blocks(title="Mental Health Support Assistant") as demo:
    # Initialize on first load
    demo.load(initialize_system)
    
    gr.Markdown("""
    # 🧠 Mental Health Support Assistant
    
    **Powered by AI** - Get information and support based on mental health resources
    
    Ask questions about mental health topics, coping strategies, and wellness!
    """)
    
    with gr.Row():
        with gr.Column():
            question_input = gr.Textbox(
                label="Your Question",
                placeholder="Ask about mental health topics, coping strategies, or wellness advice...",
                lines=3
            )
            
            ask_btn = gr.Button("🔍 Get Answer", variant="primary", size="lg")
    
    answer_output = gr.Textbox(
        label="Answer",
        lines=10,
        interactive=False
    )
    
    gr.Markdown("""
    ### 💡 How to use:
    - Ask questions about mental health topics
    - Get evidence-based information and support
    - Learn about coping strategies and wellness practices
    
    ### 📞 Crisis Resources:
    - **National Suicide Prevention Lifeline**: 988 (US)
    - **Crisis Text Line**: Text HOME to 741741
    - **International**: Find your local crisis line
    
    *This is an AI assistant providing information only. For emergencies, please contact crisis services or emergency services immediately.*
    """)
    
    # Event handlers
    ask_btn.click(
        fn=answer_question,
        inputs=[question_input],
        outputs=[answer_output]
    )
    
    # Also trigger on Enter key
    question_input.submit(
        fn=answer_question,
        inputs=[question_input],
        outputs=[answer_output]
    )

if __name__ == "__main__":
    demo.launch()