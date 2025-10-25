"""
AI utility functions for OpenAI integration.
"""
import logging
from typing import List, Dict, Any
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, SystemMessage
from config import Config

logger = logging.getLogger(__name__)

def get_openai_client() -> ChatOpenAI:
    """Get configured OpenAI client."""
    return ChatOpenAI(
        model=Config.DEFAULT_AI_MODEL,
        temperature=Config.AI_TEMPERATURE,
        openai_api_key=Config.OPENAI_API_KEY
    )

def generate_ai_response(
    system_prompt: str,
    user_prompt: str,
    temperature: float = None
) -> str:
    """
    Generate AI response using OpenAI.
    
    Args:
        system_prompt: System message for the AI
        user_prompt: User message for the AI
        temperature: Optional temperature override
        
    Returns:
        AI generated response
    """
    try:
        llm = get_openai_client()
        if temperature is not None:
            llm.temperature = temperature
            
        messages = [
            SystemMessage(content=system_prompt),
            HumanMessage(content=user_prompt)
        ]
        
        response = llm.invoke(messages)
        return response.content.strip()
        
    except Exception as e:
        logger.error(f"Error generating AI response: {e}", exc_info=True)
        raise

def extract_json_from_response(response_text: str) -> Dict[str, Any]:
    """
    Extract JSON from AI response, handling code blocks.
    
    Args:
        response_text: Raw AI response
        
    Returns:
        Parsed JSON data
    """
    import json
    
    # Try to extract JSON if wrapped in markdown code blocks
    if "```json" in response_text:
        start = response_text.find("```json") + 7
        end = response_text.find("```", start)
        response_text = response_text[start:end].strip()
    elif "```" in response_text:
        start = response_text.find("```") + 3
        end = response_text.find("```", start)
        response_text = response_text[start:end].strip()
    
    try:
        return json.loads(response_text)
    except json.JSONDecodeError as e:
        logger.warning(f"Failed to parse JSON response: {e}")
        raise ValueError(f"Invalid JSON response: {e}")
